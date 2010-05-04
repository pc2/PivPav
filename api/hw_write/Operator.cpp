/*
 * The base Operator class, every operator should inherit it
 *
 * Author : Florent de Dinechin
 *
 * This file is part of the FloPoCo project developed by the Arenaire
 * team at Ecole Normale Superieure de Lyon
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or 
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  
*/


#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <cstdlib>
#include "Operator.hpp"


void 
Operator::addPort(
  const std::string name, const int width, 
  bool isIn,     bool isClk, 
  bool isRst,    bool isCE, 
  bool isSigned, bool isUnsigned, 
  bool isFP,     int  exp_sz,
  int  fra_sz,   bool isRegistered) 
{

	if (signalMap_.find(name) != signalMap_.end()) {
		std::ostringstream o;
		o << "ERROR in " << __FUNCTION__ << ", port: '" << name<< "' seems to already exist";
		throw o.str();
	}

/*
  std::cerr << "addPort( " << endl << \
    "\t name  = " << name  << endl << \
    "\t widht = " << width << endl << \
    "\t isIn  = " << isIn  << endl << \
    "\t isClk = " << isClk << endl << \
    "\t isRst = " << isRst << endl << \
    "\t isSign= " << isSigned << endl << \
    "\t isUnsi= " << isUnsigned << endl << \
    "\t isFP  = " << isFP << endl << \
    "\t exp_sz= " << exp_sz << endl << \
    "\t fra_sz= " << fra_sz << endl << \
    "\t isReg = " << isRegistered << ");"<< endl;
*/
  Signal::SignalType inout = Signal::in;
  if (isIn==0) { inout = Signal::out; }

  Signal *s;
  if (isFP==0) {
    s = new Signal(name, inout, width) ; 
  } else {
    s = new Signal(name, inout, exp_sz, fra_sz) ;
  }

  s->setClk(isClk);
  s->setRst(isRst);
  s->setCE(isCE);
  s->setSigned(isSigned);
  s->setUnsigned(isUnsigned);
  s->setRegistered(isRegistered);

  //isConst
  //Value

  // add signal to component
	ioList_.push_back(s);
	signalMap_[name] = s ;
	numberOfInputs_ ++;
}

void Operator::addInput(const std::string name, const int width) {
	if (signalMap_.find(name) != signalMap_.end()) {
		std::ostringstream o;
		o << "ERROR in addInput, signal " << name<< " seems to already exist";
		throw o.str();
	}
	Signal *s = new Signal(name, Signal::in, width) ; // default TTL and cycle OK
  s->setClk(0);
  s->setRst(0);
  s->setCE(0);
  s->setSigned(0);
  s->setRegistered(0);
	ioList_.push_back(s);
	signalMap_[name] = s ;
	numberOfInputs_ ++;
}

void Operator::addOutput(const std::string name, const int width, const int numberOfPossibleOutputValues) {
	if (signalMap_.find(name) != signalMap_.end()) {
		std::ostringstream o;
		o << "ERROR in addInput, signal " << name << " seems to already exist";
		throw o.str();
	}
	Signal *s = new Signal(name, Signal::out, width) ;
	s -> setNumberOfPossibleValues(numberOfPossibleOutputValues);
	ioList_.push_back(s);
	for(int i=0; i<numberOfPossibleOutputValues; i++) 
		testCaseSignals_.push_back(s);
	signalMap_[name] = s ;
	numberOfOutputs_ ++;
}

void Operator::addFPInput(const std::string name, const int wE, const int wF) {
	if (signalMap_.find(name) != signalMap_.end()) {
		cerr << "ERROR in addInput , signal " << name<< " seems to already exist" << endl;
		exit(EXIT_FAILURE);
	}
	Signal *s = new Signal(name, Signal::in, wE, wF);
	ioList_.push_back(s);
	signalMap_[name] = s ;
	numberOfInputs_ ++;
}

void Operator::addFPOutput(const std::string name, const int wE, const int wF, const int numberOfPossibleOutputValues) {
	if (signalMap_.find(name) != signalMap_.end()) {
		cerr << "ERROR in addInput , signal " << name<< " seems to already exist" << endl;
		exit(EXIT_FAILURE);
	}
	Signal *s = new Signal(name, Signal::out, wE, wF) ;
	s -> setNumberOfPossibleValues(numberOfPossibleOutputValues);
	ioList_.push_back(s);
	for(int i=0; i<numberOfPossibleOutputValues; i++) 
		testCaseSignals_.push_back(s);
	signalMap_[name] = s ;
	numberOfOutputs_ ++;
}


Signal * Operator::getSignalByName(string name) {
	ostringstream e;
	if(signalMap_.find(name) ==  signalMap_.end()) {
		e << "ERROR in getSignalByName, signal " << name<< " not declared";
		throw e.str();
	}
	return signalMap_[name];
}

std::string  Operator::getCEName() {
    int size = getIOListSize();
    for (int i = 0; i<size; i++) {
      Signal *s = getIOListSignal(i);
      if (s->isRst() == 1 ) { 
        return s->getName();
      }
    }
    return "";
}

std::string  Operator::getRstName() {
    int size = getIOListSize();
    for (int i = 0; i<size; i++) {
      Signal *s = getIOListSignal(i);
      if (s->isRst() == 1) { 
        return s->getName();
      }
    }
    return "";
}

/* should be only one Clk */
int Operator::rmClk() {
  int cnt = 0;
  std::string clk = getClkName();
  while ( clk.compare("") !=0 )  {
    cnt++;
    getSignalByName(clk)->setClk(0);
    clk = getClkName();
  }
  return cnt;
}

int Operator::setClk(std::string name) {
  rmClk();
  if ( Signal *s = getSignalByName(name) ) {
    s->setClk(1);
    return 1;
  }
  return 0;
}

std::string  Operator::getClkName() {
    int size = getIOListSize();
    for (int i = 0; i<size; i++) {
      Signal *s = getIOListSignal(i);
      if (s->isClk() == 1) { 
        return s->getName();
      }
    }
    return "";
}


void Operator::setName(std::string prefix, std::string postfix){
		ostringstream pr, po;
		if (prefix.length()>0)
			pr << prefix << "_"; 
		else 
			pr << "";
		if (postfix.length()>0)
			po << "_"<<postfix;
		else
			po << "";
		uniqueName_ = pr.str() + uniqueName_ + po.str();
}

void Operator::setName(std::string operatorName){
	uniqueName_ = operatorName;
}


void  Operator::changeName(std::string operatorName){
	commentedName_ = uniqueName_;
	uniqueName_ = operatorName;
}


string Operator::getName() const{
  return uniqueName_;
}

int Operator::getIOListSize() const{
  return ioList_.size();
}

vector<Signal*> * Operator::getIOList(){
  return &ioList_; 
}

Signal * Operator::getIOListSignal(int i){
  return ioList_[i];
}
			
 

void  Operator::outputVHDLSignalDeclarations(std::ostream& o) {
	for (unsigned int i=0; i < this->signalList_.size(); i++){
		Signal* s = this->signalList_[i];
		o<<tab<<  s->toVHDL() << ";" << endl;
	}
}


void Operator::outputVHDLComponent(std::ostream& o, std::string name) {
	unsigned int i;
  if(isSequential() && getClkName().compare("") == 0) {
    std::cerr << "-- Can't find clock port for sequential component" << std::endl;
  }

	o << tab << "component " << name << " is" << endl;
	if (ioList_.size() > 0)
	{
		o << tab << tab << "port ( " << endl;

/*		if(isSequential()) {
      o << getClkName() << " : in std_logic;" <<endl;
      std::string rst = getRstName();
      if (rst.compare("") != 0) {
        o << rst << " : in std_logic;" <<endl;
      }
		}
*/
		for (i=0; i<this->ioList_.size(); i++){
			Signal* s = this->ioList_[i];
//			if (i>0 || isSequential()) // align signal names 
//				o<<tab<<"          ";
			o<< tab << tab << tab << s->toVHDL();
			if(i < this->ioList_.size()-1)  o<<";" << endl;
		}
		o << endl << tab << ");"<<endl;
	}
	o << tab << "end component;" << endl;
}

void Operator::outputVHDLComponent(std::ostream& o) {
	this->outputVHDLComponent(o,  this->uniqueName_); 
}


void Operator::outputVHDLEntity(std::ostream& o) {
	unsigned int i;
  if(isSequential() && getClkName().compare("") == 0) {
    std::cerr << "-- Can't find clock port for sequential component" << std::endl;
  }
	o << "entity " << uniqueName_ << " is" << endl;
	if (ioList_.size() > 0)
	{
		o << tab << "port ( " << endl;

/*
		if(isSequential()) {
      o << getClkName() << " : in std_logic;" <<endl;
      std::string rst = getRstName();
      if (rst.compare("") != 0) {
        o << rst << " : in std_logic;" <<endl;
      }
		}
*/
		for (i=0; i<this->ioList_.size(); i++){
			Signal* s = this->ioList_[i];
//			if (i>0 || isSequential()) // align signal names 
//				o<<"          ";
			o<< tab << tab << tab << s->toVHDL();
			if(i < this->ioList_.size()-1)  o<<";" << endl;
		}
	
		o << endl << tab << ");"<<endl;
	}
	o << "end entity;" << endl << endl;
}


void Operator::setCopyrightString(std::string authorsYears){
	copyrightString_ = authorsYears;
}


void Operator::licence(std::ostream& o){
	licence(o, copyrightString_);
}


void Operator::licence(std::ostream& o, std::string authorsyears){
	o<<"--------------------------------------------------------------------------------"<<endl;
	// centering the unique name
	int s, i;
	if(uniqueName_.size()<76) s = (76-uniqueName_.size())/2; else s=0;
	o<<"--"; for(i=0; i<s; i++) o<<" "; o  << uniqueName_ << endl; 

	// if this operator was renamed from the command line, show the original name
	if(commentedName_!="") {
		if(commentedName_.size()<74) s = (74-commentedName_.size())/2; else s=0;
		o<<"--"; for(i=0; i<s; i++) o<<" "; o << "(" << commentedName_ << ")" << endl; 
	}

	o<<"-- This operator is part of the Infinite Virtual Library FloPoCoLib"<<endl
	 <<"-- and is distributed under the terms of the GNU Lesser General Public Licence."<<endl
	 <<"-- Authors: " << authorsyears <<endl
	 <<"--------------------------------------------------------------------------------"<<endl;
}

void Operator::outputVHDL(std::ostream& o) {
	this->outputVHDL(o, this->uniqueName_); 
}

bool Operator::isSequential() {
	return isSequential_; 
}

void Operator::setSequential() {
	isSequential_=1; 
}

void Operator::setCombinatorial() {
	isSequential_=0; 
}

int Operator::getPipelineDepth() {
	return pipelineDepth_; 
}

void Operator::setPipelineDepth(int d) {
	pipelineDepth_=d; 
}

void Operator::outputFinalReport() {
	cout << "Entity " << uniqueName_ <<":"<< endl;
	if(this->getPipelineDepth()!=0)
		cout << tab << "Pipeline depth = " << getPipelineDepth() << endl;
	else
		cout << tab << "Not pipelined"<< endl;
}



void Operator::setCycle(int cycle, bool report) {
	if(isSequential()) {
		currentCycle_=cycle;
		if(report)
			vhdl << tab << "----------------Synchro barrier, entering cycle " << currentCycle_ << "----------------" << endl ;
		// automatically update pipeline depth of the operator 
		if (currentCycle_ > pipelineDepth_) 
			pipelineDepth_ = currentCycle_;
	}
}

void Operator::nextCycle(bool report) {
	if(isSequential()) {
		currentCycle_ ++; 
		if(report)
			vhdl << tab << "----------------Synchro barrier, entering cycle " << currentCycle_ << "----------------" << endl ;
		// automatically update pipeline depth of the operator 
		if (currentCycle_ > pipelineDepth_) 
			pipelineDepth_ = currentCycle_;
	}
}


void Operator::setCycleFromSignal(string name, bool report) {
	ostringstream e;
	e << "ERROR in syncCycleFromSignal, "; // just in case

	if(isSequential()) {
		Signal* s;
		try {
			s=getSignalByName(name);
		}
		catch (string e2) {
			e << endl << tab << e2;
			throw e.str();
		}

		if( s->getCycle() < 0 ) {
			ostringstream o;
			o << "signal " << name<< " doesn't have (yet?) a valid cycle";
		throw o.str();
		} 
		currentCycle_ = s->getCycle();
		if(report)
			vhdl << tab << "----------------Synchro barrier, entering cycle " << currentCycle_ << "----------------" << endl ;
		// automatically update pipeline depth of the operator 
		if (currentCycle_ > pipelineDepth_) 
			pipelineDepth_ = currentCycle_;
	}
}


void Operator::syncCycleFromSignal(string name, bool report) {
	ostringstream e;
	e << "ERROR in syncCycleFromSignal, "; // just in case

	if(isSequential()) {
		Signal* s;
		try {
			s=getSignalByName(name);
		}
		catch (string e2) {
			e << endl << tab << e2;
			throw e.str();
		}

		if( s->getCycle() < 0 ) {
			ostringstream o;
			o << "signal " << name << " doesn't have (yet?) a valid cycle";
		throw o.str();
		} 
		// advance cycle if needed
		if (s->getCycle()>currentCycle_)
			currentCycle_ = s->getCycle();

		if(report)
			vhdl << tab << "----------------Synchro barrier, entering cycle " << currentCycle_ << "----------------" << endl ;
		// automatically update pipeline depth of the operator 
		if (currentCycle_ > pipelineDepth_) 
			pipelineDepth_ = currentCycle_;
	}
}



string Operator::declare(string name, const int width, bool isbus) {
	Signal* s;
	ostringstream e;
	// check the signals doesn't already exist
	if(signalMap_.find(name) !=  signalMap_.end()) {
		e << "ERROR in declare(), signal " << name<< " already exists";
		throw e.str();
	}
	// construct the signal (lifeSpan and cycle are reset to 0 by the constructor)
	s = new Signal(name, Signal::wire, width, isbus);
	// define its cycle 
	if(isSequential())
		s->setCycle(this->currentCycle_);
	// add the signal to signalMap and signalList
	signalList_.push_back(s);    
	signalMap_[name] = s ;
	return name;
}



string Operator::use(string name) {
	ostringstream e;
	e << "ERROR in use(), "; // just in case
	
	if(isSequential()) {
		Signal *s;
		try {
			s=getSignalByName(name);
		}
		catch (string e2) {
			e << endl << tab << e2;
			throw e.str();
		}
		if(s->getCycle() < 0) {
			e << "signal " << name<< " doesn't have (yet?) a valid cycle";
			throw e.str();
		} 
		if(s->getCycle() > currentCycle_) {
			ostringstream e;
			e << "active cycle of signal " << name<< " is later than current cycle, cannot delay it";
			throw e.str();
		} 
		// update the lifeSpan of s
		s->updateLifeSpan( currentCycle_ - s->getCycle() );
		return s->delayedName( currentCycle_ - s->getCycle() );
	}
	else
		return name;
}


void Operator::outPortMap(Operator* op, string componentPortName, string actualSignalName){
	Signal* formal;
	Signal* s;
	ostringstream e;
	e << "ERROR in outPortMap(), "; // just in case
	// check the signals doesn't already exist
	if(signalMap_.find(actualSignalName) !=  signalMap_.end()) {
		e << "signal " << actualSignalName << " already exists";
		throw e.str();
	}
	try {
		formal=op->getSignalByName(componentPortName);
	}
	catch (string e2) {
		e << endl << tab << e2;
		throw e.str();
	}
	if (formal->type()!=Signal::out){
		e << "signal " << componentPortName << " of component " << op->getName() 
		  << " doesn't seem to be an output port";
		throw e.str();
	}
	int width = formal -> width();
	bool isbus = formal -> isBus();
	// construct the signal (lifeSpan and cycle are reset to 0 by the constructor)
	s = new Signal(actualSignalName, Signal::wire, width, isbus);
	// define its cycle 
	if(isSequential())
		s->setCycle( this->currentCycle_ + op->getPipelineDepth() );
	// add the signal to signalMap and signalList
	signalList_.push_back(s);    
	signalMap_[actualSignalName] = s ;

	// add the mapping to the mapping list of Op
	op->portMap_[componentPortName] = actualSignalName;
}


void Operator::inPortMap(Operator* op, string componentPortName, string actualSignalName){
	Signal* formal;
	ostringstream e;
	string name;
	e << "ERROR in inPortMap(), "; // just in case
	
	if(isSequential()) {
		Signal *s;
		try {
			s=getSignalByName(actualSignalName);
		}
		catch (string e2) {
			e << endl << tab << e2;
			throw e.str();
		}
		if(s->getCycle() < 0) {
			ostringstream e;
			e << "signal " << actualSignalName<< " doesn't have (yet?) a valid cycle";
			throw e.str();
		} 
		if(s->getCycle() > currentCycle_) {
			ostringstream e;
			e << "active cycle of signal " << actualSignalName<< " is later than current cycle, cannot delay it";
			throw e.str();
		} 
		// update the lifeSpan of s
		s->updateLifeSpan( currentCycle_ - s->getCycle() );
		name = s->delayedName( currentCycle_ - s->getCycle() );
	}
	else
		name = actualSignalName;

	try {
		formal=op->getSignalByName(componentPortName);
	}
	catch (string e2) {
		e << endl << tab << e2;
		throw e.str();
	}
	if (formal->type()!=Signal::in){
		e << "signal " << componentPortName << " of component " << op->getName() 
		  << " doesn't seem to be an input port";
		throw e.str();
	}

	// add the mapping to the mapping list of Op
	op->portMap_[componentPortName] = name;
}



void Operator::inPortMapCst(Operator* op, string componentPortName, string actualSignal){
	Signal* formal;
	ostringstream e;
	string name;
	e << "ERROR in inPortMap(), "; // just in case

	try {
		formal=op->getSignalByName(componentPortName);
	}
	catch (string e2) {
		e << endl << tab << e2;
		throw e.str();
	}
	if (formal->type()!=Signal::in){
		e << "signal " << componentPortName << " of component " << op->getName() 
		  << " doesn't seem to be an input port";
		throw e.str();
	}

	// add the mapping to the mapping list of Op
	op->portMap_[componentPortName] = actualSignal;
}


string Operator::instance(Operator* op, string instanceName){
	ostringstream o;
	// TODO add checks here? Check that all the signals are covered for instance
	
  if(isSequential() && getClkName().compare("") == 0) {
    std::cerr << "-- Can't find clock port for sequential component" << std::endl;
  }

	o << tab << instanceName << ": " << op->getName();
	if (isSequential()) 
		o << "  -- pipelineDepth="<< op->getPipelineDepth();
	o << endl;
	o << tab << tab << "port map (";
	// build vhdl and erase portMap_
	map<string,string>::iterator it;
/*	if(isSequential()) {
		o <<            " clk  => clk, " << endl;
		o <<  tab <<tab << "           rst  => rst, " << endl;
	}
*/
	it=op->portMap_.begin();
//	if(isSequential()) 
//		o << tab << tab << "           " ;
//	else
		o <<  " " ;
	o<< (*it).first << " => "  << (*it).second;
	//op->portMap_.erase(it);
	it++;
	for (  ; it != op->portMap_.end(); it++ ) {
		o << "," << endl;
		o <<  tab << tab << "           " << (*it).first << " => "  << (*it).second;
		//op->portMap_.erase(it);
	}
	o << ");" << endl;

	// add the operator to the subcomponent list 
	subComponents_[op->getName()]  = op;
	return o.str();
}
	



string Operator::buildVHDLSignalDeclarations() {
	ostringstream o;
	for(unsigned int i=0; i<signalList_.size(); i++) {
		Signal *s = signalList_[i];
		o << s->toVHDLDeclaration() << endl;
	}
	
	return o.str();	
}



string Operator::buildVHDLComponentDeclarations() {
	ostringstream o;
	for(map<string, Operator*>::iterator it = subComponents_.begin(); it !=subComponents_.end(); it++) {
		Operator *op = it->second;
		op->outputVHDLComponent(o);
		o<< endl;
	}
	return o.str();	
}

string  Operator::buildVHDLRegisters() {
	ostringstream o,l;

	if (isSequential()){

  if(getClkName().compare("") == 0) {
    std::cerr << "-- Can't find clock port for sequential component" << std::endl;
    return "";
  }

    std::string clk = getClkName();
    o << "-- clkname = " << clk << endl;
		o << tab << "process("<< clk <<")  begin\n"
		  << tab << tab << "if "<< clk << "'event and "<< clk <<"= '1' then\n";
		for(unsigned int i=0; i<signalList_.size(); i++) {
			Signal *s = signalList_[i];
			if(s->getLifeSpan() >0) {
				for(int j=1; j <= s->getLifeSpan(); j++)
					l << tab <<tab << tab << s->delayedName(j) << " <=  " << s->delayedName(j-1) <<";" << endl;
			}
		}
    // when there are not registers then we don't need that process stmnt
    if (l.str().compare("") == 0) return l.str();
    o << l.str();
		o << tab << tab << "end if;\n";
		o << tab << "end process;\n"; 
	}
	return o.str();
}


void Operator::outputVHDL(std::ostream& o, std::string name) {

  if(isSequential() && getClkName().compare("") == 0) {
    std::cerr << "-- Can't find clock port for sequential component." << std::endl;
  }

	licence(o);
	stdLibs(o);
	outputVHDLEntity(o);
	newArchitecture(o,name);
	o << buildVHDLComponentDeclarations();	
	o << buildVHDLSignalDeclarations();
	beginArchitecture(o);		
	o<<buildVHDLRegisters();
	o << vhdl.str();
	endArchitecture(o);
}
