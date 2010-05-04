#ifndef OPERATOR_HPP
#define OPERATOR_HPP
#include <vector>
#include <map>
/* #include <gmpxx.h> */
#include "Signal.hpp"

using namespace std;

// variables set by the command-line interface in main.cpp

extern  int verbose;
const std::string tab = "   ";

/**
 * This is a top-level class representing an Operator.
 * This class is inherited by all classes which will output a VHDL entity.
 */
class Operator
{

public:
  // copy constructor
  Operator(const Operator &o)  {
    numberOfInputs_             = o.numberOfInputs_;
    numberOfOutputs_            = o.numberOfOutputs_;
    hasRegistersWithoutReset_   = o.hasRegistersWithoutReset_;
    hasRegistersWithAsyncReset_ = o.hasRegistersWithAsyncReset_;
    hasRegistersWithSyncReset_  = o.hasRegistersWithSyncReset_;
    pipelineDepth_              = o.pipelineDepth_;
    currentCycle_               = o.currentCycle_;
    uniqueName_      = o.uniqueName_;
    isSequential_    = o.isSequential_;
    commentedName_   = o.commentedName_;
    copyrightString_ = o.copyrightString_;
    signalList_      = o.signalList_;
    portMap_         = o.portMap_;
    outDelayMap      = o.outDelayMap;
    signalMap_       = o.signalMap_;
    ioList_          = o.ioList_;
    testCaseSignals_ = o.testCaseSignals_;
    subComponents_   = o.subComponents_;
}

	/** Default constructor.
	 * Creates a default operator instance. No parameters are passed to this constructor.
	 */
	Operator(){
		numberOfInputs_             = 0;
		numberOfOutputs_            = 0;
		hasRegistersWithoutReset_   = false;
		hasRegistersWithAsyncReset_ = false;
		hasRegistersWithSyncReset_  = false;
		pipelineDepth_              = 0;
		currentCycle_                      = 0;
	}
	
	/** Operator Destructor.
	 */	
	virtual ~Operator() {}


 /*****************************************************************************/
 /*         Paperwork-related methods (for defining an operator entity)       */
 /*****************************************************************************/

	/** Adds an input signal to the operator.
	 * Adds a signal of type Signal::in to the the I/O signal list.
	 * @param name  the name of the signal
	 * @param width the number of bits of the signal.
	 */
	void addInput  (const std::string name, const int width=1);

  void addPort(
    const std::string name, const int width, 
    bool isIn,     bool isClk, 
    bool isRst,    bool isCE, 
    bool isSigned, bool isUnsigned, 
    bool isFP,     int  exp_sz,
    int  fra_sz,   bool isRegistered);


	/** Adds an output signal to the operator.
	 * Adds a signal of type Signal::out to the the I/O signal list.
	 * @param name  the name of the signal
	 * @param width the number of bits of the signal.
	 * @param numberOfPossibleOutputValues (optional, defaults to 1) set to 2 for a faithfully rounded operator for instance
	 */	
	void addOutput(const std::string name, const int width=1, const int numberOfPossibleOutputValues=1);
	

	/** Adds a floating point input signal to the operator.
	 * Adds a signal of type Signal::in to the the I/O signal list, 
	 * having the FP flag set on true. The total width of this signal will
	 * be wE + wF + 3. (2 bits for exception, 1 for sign)
	 * @param name the name of the signal
	 * @param wE   the width of the exponent
	 * @param wF   the withh of the fraction
	 */
	void addFPInput(const std::string name, const int wE, const int wF);


	/** Adds a floating point output signal to the operator.
	 * Adds a signal of type Signal::out to the the I/O signal list, 
	 * having the FP flag set on true. The total width of this signal will
	 * be wE + wF + 3. (2 bits for exception, 1 for sign)
	 * @param name the name of the signal
	 * @param wE   the width of the exponent
	 * @param wF   the withh of the fraction
	 * @param numberOfPossibleOutputValues (optional, defaults to 1) set to 2 for a faithfully rounded operator for instance
	 */	
	void addFPOutput(const std::string name, const int wE, const int wF, const int numberOfPossibleOutputValues=1);

	

	/** sets the copyright string, should be authors + year
	 * @param authorsYears the names of the authors and the years of their contributions
	 */
	void setCopyrightString(std::string authorsYears);


	/** Sets Operator name to givenName.
	 * Sets the name of the operator to operatorName.
	 * @param operatorName new name of the operator
	*/
	void setName(std::string operatorName = "UnknownOperator");
	
	/** This method should be used by an operator to change the default name of a sub-component. The default name becomes the commented name.
	 * @param operatorName new name of the operator
	*/
	void changeName(std::string operatorName);
	
	/** Sets Operator name to prefix_(uniqueName_)_postfix
	 * @param prefix the prefix string which will be placed in front of the operator name
	 *               formed with the operator internal parameters
	 * @param postfix the postfix string which will be placed at the end of the operator name
	 *                formed with the operator internal parameters
	*/
	void setName(std::string prefix, std::string postfix);
		
	/** Return the operator name. 
	 * Returns a string value representing the name of the operator. 
	 * @return operator name
	 */
	string getName() const;




 /*****************************************************************************/
 /*        VHDL-related methods (for defining an operator architecture)       */
 /*****************************************************************************/



	/* Functions related to pipeline management */

	/** Define the current cycle 
	 * @param the new value of the current cycle */
	void setCycle(int cycle, bool report=true) ;


	/** Define the current cycle 
	 * @param the new value of the current cycle */
	void nextCycle(bool report=true) ;


	/** Set the current cycle to that of a signal. It may increase or decrease current cycle. 
	 * @param name is the signal name. It must have been defined before 
	 * @param report is a boolean, if true it will report the cycle 
	 */
	void setCycleFromSignal(string name, bool report=false) ;

	/** advance the current cycle to that of a signal. It may only increase current cycle. To synchronize
		 two or more signals, first call setCycleFromSignal() on the
		 first, then syncCycleFromSignal() on the remaining ones. It
		 will synchronize to the latest of these signals.  
		 * @param name is the signal name. It must have been defined before 
		 * @param report is a boolean, if true it will report the cycle 
		 */
	void syncCycleFromSignal(string name, bool report=true) ;


	/** Declares a signal implicitely by having it appearing on the Left Hand Side of a VHDL assignment
	 * @param name is the name of the signal
	 * @param width is the width of the signal (optional, default 1)
	 * @param isbus: a signal of width 1 is declared as std_logic when false, as std_logic_vector when true (optional, default false)
	 * @return name
	 */
	string declare(string name, const int width=1, bool isbus=false);
	// TODO: add methods that allow for signals with reset (when rewriting LongAcc for the new framework)


	/** use a signal on the Right 
	 * @param name is the name of the signal
	 * @return name
	 */
	string use(string name);


	/** Declare an output mapping for an instance of a sub-component
	 * Also declares the local signal implicitely, with width taken from the component 	
	 * @param op is a pointer to the subcomponent
	 * @param componentPortName is the name of the port on the component
	 * @param actualSignalName is the name of the signal in This mapped to this port
	 * @return name
	 */
	void outPortMap(Operator* op, string componentPortName, string actualSignalName);


	/** use a signal as input of a subcomponent
	 * @param componentPortName is the name of the port on the component
	 * @param actualSignalName is the name of the signal (of this) mapped to this port
	 */
	void inPortMap(Operator* op, string componentPortName, string actualSignalName);


	/** use a constant signal as input of a subcomponent. 
	 * @param componentPortName is the name of the port on the component
	 * @param actualSignal is the constant signal to be mapped to this port
	 */
	void inPortMapCst(Operator* op, string componentPortName, string actualSignal);


	/** returns the VHDL for an instance of a sub-component. 
	 * @param componentPortName is the name of the port on the component
	 * @param actualSignalName is the name of the signal (of this) mapped to this port
	 * @return name
	 */
	string instance(Operator* op, string instanceName);


	/**
	 * A new architecture inline function
	 * @param[in,out] o 	- the stream to which the new architecture line will be added
	 * @param[in]     name	- the name of the entity corresponding to this architecture
	 **/
	inline void newArchitecture(std::ostream& o, std::string name){
		o << "architecture arch of " << name  << " is" << endl;
	}

	
	/**
	 * A begin architecture inline function 
	 * @param[in,out] o 	- the stream to which the begin line will be added
	 **/
	inline void beginArchitecture(std::ostream& o){
		o << "begin" << endl;
	}


	/**
	 * A end architecture inline function 
	 * @param[in,out] o 	- the stream to which the begin line will be added
	 **/
	inline void endArchitecture(std::ostream& o){
		o << "end architecture;" << endl << endl;
	}


 /*****************************************************************************/
 /*     From this point, we have methods that are not needed in normal use    */
 /*****************************************************************************/



	
	/** build all the signal declarations from signals implicitely declared by declare().
	 *  This is the 2.0 equivalent of outputVHDLSignalDeclarations
	 */
	string buildVHDLSignalDeclarations();

	/** build all the component declarations from the list built by instance().
	 */
	string buildVHDLComponentDeclarations();

	/** build all the registers from signals implicitely delayed by declare() 
	 *	 This is the 2.0 equivalent of outputVHDLSignalRegisters
	 */
	string buildVHDLRegisters();

	/** the main function outputs the VHDL for the operator.
		 If you use the modern (post-0.10) framework you no longer need to overload this method,
		 the default will do.
	 * @param o the stream where the entity will outputted
	 * @param name the name of the architecture
	 */
	virtual void outputVHDL(std::ostream& o, std::string name);
	
	/** the main function outputs the VHDL for the operator 
	 * @param o the stream where the entity will outputted
	 */	
	void outputVHDL(std::ostream& o);   // calls the previous with name = uniqueName

	/** True if the operator needs a clock signal; 
	 * It will also get a rst but doesn't need to use it.
	 */	
	bool isSequential();  
	
	/** Set the operator to sequential.
		 You shouldn't need to use this method for standard operators 
		 (Operator::Operator()  calls it according to Target)
	 */	
	void setSequential(); 
	
	/** Set the operator to combinatorial
		 You shouldn't need to use this method for standard operators 
		 (Operator::Operator()  calls it according to Target)
	 */	
	void setCombinatorial();

	/** Returns a pointer to the signal having the name s. Throws an exception if the signal is not yet declared.
	  * @param s then name of the signal we want to return
	  * @return the pointer to the signal having name s 
	  */
	Signal* getSignalByName(string s);

  int setClk(std::string);
  int rmClk();
  std::string  getClkName();
  std::string  getRstName();
  std::string  getCEName();

	/** DEPRECATED Outputs component declaration 
	 * @param o the stream where the component is outputed
	 * @param name the name of the VHDL component we want to output to o
	 */
	virtual void outputVHDLComponent(std::ostream& o, std::string name);
	
	/**  DEPRECATED Outputs the VHDL component code of the current operator
	 * @param o the stream where the component is outputed
	 */
	void outputVHDLComponent(std::ostream& o);  
	

	/** Return the number of input+output signals 
	 * @return the size of the IO list. The total number of input and output signals
	 *         of the architecture.
	 */
	int getIOListSize() const;
	
	/** Returns a pointer to the list containing the IO signals.
	 * @return pointer to ioList 
	 */
	vector<Signal*> * getIOList();
	
	/** Returns a pointer a signal from the ioList.
	 * @param the index of the signal in the list
	 * @return pointer to the i'th signal of ioList 
	 */
	Signal * getIOListSignal(int i);
		
	/** DEPRECATED, better use setCopyrightString
		 Output the licence
	 * @param o the stream where the licence is going to be outputted
	 * @param authorsYears the names of the authors and the years of their contributions
	 */
	void licence(std::ostream& o, std::string authorsYears);


	/**  Output the licence, using copyrightString_
	 * @param o the stream where the licence is going to be outputted
	 */
	void licence(std::ostream& o);

	/** DEPRECATED  Output the standard library paperwork 
	 * @param o the stream where the libraries will be written to
	 */
	static void stdLibs(std::ostream& o){
		o<<"library ieee;\nuse ieee.std_logic_1164.all;"<<endl 
		 <<"use ieee.std_logic_arith.all;"<<endl
		 <<"use ieee.std_logic_unsigned.all;"<<endl 
		 <<"library work;"<<endl<<endl;
	};
		
	/** DEPRECATED  Output the VHDL entity of the current operator.
	 * @param o the stream where the entity will be outputted
	 */
	void outputVHDLEntity(std::ostream& o);
	
	/** DEPRECATED  output all the signal declarations 
	 * @param o the stream where the signal deca
	 */
	void outputVHDLSignalDeclarations(std::ostream& o);

	/**
	 * A new line inline function
	 * @param[in,out] o the stream to which the new line will be added
	 **/
	inline void newLine(std::ostream& o) {	o<<endl; }
	

	/** Final report function, prints to the terminal.  By default
	 * reports the pipeline depth, but feel free to overload if you have any
	 * thing useful to tell to the end user
	*/
	virtual void outputFinalReport();	
	
	/** DEPRECATED Set the depth of the pipeline
		 You shouldn't need to use this method for standard operators 
		 (Operator::Operator()  calls it according to Target)
	 * @param d the depth of the pipeline for the operator
	 */	
	void setPipelineDepth(int d);
	
	/** DEPRECATED Gets the pipeline depth of this operator 
	 * @return the pipeline depth of the operator
	*/
	int getPipelineDepth();
	

protected:    
	string              uniqueName_;      /**< By default, a name derived from the operator class and the parameters */
	vector<Signal*>     ioList_;          /**< The list of I/O signals of the operator */
	vector<Signal*>     testCaseSignals_; /**< The list of pointers to the signals in a test case entry. Its size also gives the dimension of a test case */
	vector<Signal*>     signalList_;      /**< The list of internal signals of the operator */
	map<string, Operator*> subComponents_;/**< The list of sub-components */
	map<string, string> portMap_;         /**< Port map for an instance of this operator */
	map<string, double> outDelayMap;      /**< Slack delays on the outputs */
	ostringstream       vhdl;             /**< The internal stream to which the constructor will build the VHDL code */
// private:
	int                    numberOfInputs_;             /**< The number of inputs of the operator */
	int                    numberOfOutputs_;            /**< The number of outputs of the operator */
	bool                   isSequential_;               /**< True if the operator needs a clock signal*/
	int                    pipelineDepth_;              /**< The pipeline depth of the operator. 0 for combinatorial circuits */
	map<string, Signal*>   signalMap_;                  /**< A container of tuples for recovering the signal based on it's name */ 
	bool                   hasRegistersWithoutReset_;   /**< True if the operator has registers without a reset */
	bool                   hasRegistersWithAsyncReset_; /**< True if the operator has registers having an asynch reset */
	bool                   hasRegistersWithSyncReset_;  /**< True if the operator has registers having a synch reset */
	string                 commentedName_;              /**< Usually is the default name of the architecture.  */
	string                 copyrightString_;            /**< Authors and years.  */
	int                    currentCycle_;               /**< The current cycle, when building a pipeline */

};

#endif
