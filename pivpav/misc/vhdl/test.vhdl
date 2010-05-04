--------------------------------------------------------------------------------
--                   FPAdder_32_32_32_32_32_32_DualSubClose
--                              (IntDualSub_35)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- and is distributed under the terms of the GNU Lesser General Public Licence.
-- Authors: Bogdan Pasca (2008)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;

entity FPAdder_32_32_32_32_32_32_DualSubClose is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(34 downto 0);
          Y : in  std_logic_vector(34 downto 0);
          RxMy : out  std_logic_vector(34 downto 0);
          RyMx : out  std_logic_vector(34 downto 0)   );
end entity;

architecture arch of FPAdder_32_32_32_32_32_32_DualSubClose is
   signal X0 :  std_logic_vector(29 downto 0);
   signal Y0 :  std_logic_vector(29 downto 0);
   signal X1 :  std_logic_vector(4 downto 0);
   signal Y1 :  std_logic_vector(4 downto 0);
   signal xMycin1r0 :  std_logic_vector(30 downto 0);
   signal xMycin1r0_d :  std_logic_vector(30 downto 0);
   signal yMxcin1r0 :  std_logic_vector(30 downto 0);
   signal yMxcin1r0_d :  std_logic_vector(30 downto 0);
   signal xMyr0 :  std_logic_vector(29 downto 0);
   signal yMxr0 :  std_logic_vector(29 downto 0);
   signal xMyr1 :  std_logic_vector(4 downto 0);
   signal yMxr1 :  std_logic_vector(4 downto 0);
   signal sX0 :  std_logic_vector(29 downto 0);
   signal sY0 :  std_logic_vector(29 downto 0);
   signal cin0 : std_logic;
   signal sX1 :  std_logic_vector(4 downto 0);
   signal sX1_d :  std_logic_vector(4 downto 0);
   signal sY1 :  std_logic_vector(4 downto 0);
   signal sY1_d :  std_logic_vector(4 downto 0);
begin
   X0 <= X(29 downto 0);
   Y0 <= Y(29 downto 0);
   X1 <= X(34 downto 30);
   Y1 <= Y(34 downto 30);
   sX0 <= X0;
   sY0 <= Y0;
   cin0 <= '1';
   sX1 <= X1;
   sY1 <= Y1;
   xMycin1r0 <= ("0" & sX0) + ("0" & not(sY0)) + cin0;
   yMxcin1r0 <= ("0" & not(sX0)) + ("0" & sY0) + cin0;
   xMyr0 <= xMycin1r0_d(29 downto 0);
   xMyr1 <= sX1_d + not(sY1_d) + xMycin1r0_d(30);
   yMxr0 <= yMxcin1r0_d(29 downto 0);
   yMxr1 <= not(sX1_d) + sY1_d + yMxcin1r0_d(30);
   RxMy <= xMyr1 & xMyr0;

   RyMx <= yMxr1 & yMxr0;

   process(clk)  begin
      if clk'event and clk = '1' then
         xMycin1r0_d <=  xMycin1r0;
         yMxcin1r0_d <=  yMxcin1r0;
         sX1_d <=  sX1;
         sY1_d <=  sY1;
      end if;
   end process;
end architecture;

--------------------------------------------------------------------------------
--                    FPAdder_32_32_32_32_32_32_LZCShifter
--                     (LZCShifter_34_to_34_counting_64)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- and is distributed under the terms of the GNU Lesser General Public Licence.
-- Authors: Florent de Dinechin, Bogdan Pasca (2007)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;

entity FPAdder_32_32_32_32_32_32_LZCShifter is
   port ( clk, rst : in std_logic;
          I : in  std_logic_vector(33 downto 0);
          Count : out  std_logic_vector(5 downto 0);
          O : out  std_logic_vector(33 downto 0)   );
end entity;

architecture arch of FPAdder_32_32_32_32_32_32_LZCShifter is
signal level6, level6_d1 :  std_logic_vector(33 downto 0);
signal count5, count5_d1, count5_d2, count5_d3, count5_d4, count5_d5, count5_d6 : std_logic;
signal level5, level5_d1 :  std_logic_vector(33 downto 0);
signal count4, count4_d1, count4_d2, count4_d3, count4_d4, count4_d5 : std_logic;
signal level4, level4_d1 :  std_logic_vector(33 downto 0);
signal count3, count3_d1, count3_d2, count3_d3, count3_d4 : std_logic;
signal level3, level3_d1 :  std_logic_vector(33 downto 0);
signal count2, count2_d1, count2_d2, count2_d3 : std_logic;
signal level2, level2_d1 :  std_logic_vector(33 downto 0);
signal count1, count1_d1, count1_d2 : std_logic;
signal level1, level1_d1 :  std_logic_vector(33 downto 0);
signal count0, count0_d1 : std_logic;
signal level0 :  std_logic_vector(33 downto 0);
signal sCount :  std_logic_vector(5 downto 0);
begin
   process(clk)  begin
      if clk'event and clk = '1' then
         level6_d1 <=  level6;
         count5_d1 <=  count5;
         count5_d2 <=  count5_d1;
         count5_d3 <=  count5_d2;
         count5_d4 <=  count5_d3;
         count5_d5 <=  count5_d4;
         count5_d6 <=  count5_d5;
         level5_d1 <=  level5;
         count4_d1 <=  count4;
         count4_d2 <=  count4_d1;
         count4_d3 <=  count4_d2;
         count4_d4 <=  count4_d3;
         count4_d5 <=  count4_d4;
         level4_d1 <=  level4;
         count3_d1 <=  count3;
         count3_d2 <=  count3_d1;
         count3_d3 <=  count3_d2;
         count3_d4 <=  count3_d3;
         level3_d1 <=  level3;
         count2_d1 <=  count2;
         count2_d2 <=  count2_d1;
         count2_d3 <=  count2_d2;
         level2_d1 <=  level2;
         count1_d1 <=  count1;
         count1_d2 <=  count1_d1;
         level1_d1 <=  level1;
         count0_d1 <=  count0;
      end if;
   end process;
   level6 <= I ;
   count5<= '1' when level6(33 downto 2) = (33 downto 2=>'0') else '0';
   ----------------Synchro barrier, entering cycle 1----------------
   level5<= level6_d1(33 downto 0) when count5_d1='0' else level6_d1(1 downto 0) & (31 downto 0 => '0');

   count4<= '1' when level5(33 downto 18) = (33 downto 18=>'0') else '0';
   ----------------Synchro barrier, entering cycle 2----------------
   level4<= level5_d1(33 downto 0) when count4_d1='0' else level5_d1(17 downto 0) & (15 downto 0 => '0');

   count3<= '1' when level4(33 downto 26) = (33 downto 26=>'0') else '0';
   ----------------Synchro barrier, entering cycle 3----------------
   level3<= level4_d1(33 downto 0) when count3_d1='0' else level4_d1(25 downto 0) & (7 downto 0 => '0');

   count2<= '1' when level3(33 downto 30) = (33 downto 30=>'0') else '0';
   ----------------Synchro barrier, entering cycle 4----------------
   level2<= level3_d1(33 downto 0) when count2_d1='0' else level3_d1(29 downto 0) & (3 downto 0 => '0');

   count1<= '1' when level2(33 downto 32) = (33 downto 32=>'0') else '0';
   ----------------Synchro barrier, entering cycle 5----------------
   level1<= level2_d1(33 downto 0) when count1_d1='0' else level2_d1(31 downto 0) & (1 downto 0 => '0');

   count0<= '1' when level1(33 downto 33) = (33 downto 33=>'0') else '0';
   ----------------Synchro barrier, entering cycle 6----------------
   level0<= level1_d1(33 downto 0) when count0_d1='0' else level1_d1(32 downto 0) & (0 downto 0 => '0');

   O <= level0;
   sCount <= count5_d6 & count4_d5 & count3_d4 & count2_d3 & count1_d2 & count0_d1;
   Count <= CONV_STD_LOGIC_VECTOR(34,6) when sCount=CONV_STD_LOGIC_VECTOR(63,6)
      else sCount;
end architecture;

--------------------------------------------------------------------------------
--                   FPAdder_32_32_32_32_32_32_RightShifter
--                        (RightShifter_33_by_max_35)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- and is distributed under the terms of the GNU Lesser General Public Licence.
-- Authors: Florent de Dinechin, Bogdan Pasca (2007,2008,2009)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;

entity FPAdder_32_32_32_32_32_32_RightShifter is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(32 downto 0);
          S : in  std_logic_vector(5 downto 0);
          R : out  std_logic_vector(67 downto 0)   );
end entity;

architecture arch of FPAdder_32_32_32_32_32_32_RightShifter is
signal level0 :  std_logic_vector(32 downto 0);
signal ps, ps_d1, ps_d2 :  std_logic_vector(5 downto 0);
signal level1 :  std_logic_vector(33 downto 0);
signal level2, level2_d1 :  std_logic_vector(35 downto 0);
signal level3 :  std_logic_vector(39 downto 0);
signal level4 :  std_logic_vector(47 downto 0);
signal level5, level5_d1 :  std_logic_vector(63 downto 0);
signal level6 :  std_logic_vector(95 downto 0);
begin
   process(clk)  begin
      if clk'event and clk = '1' then
         ps_d1 <=  ps;
         ps_d2 <=  ps_d1;
         level2_d1 <=  level2;
         level5_d1 <=  level5;
      end if;
   end process;
   level0<= X;
   ps<= S;
   level1<=  (0 downto 0 => '0') & level0 when ps(0) = '1' else    level0 & (0 downto 0 => '0');
   level2<=  (1 downto 0 => '0') & level1 when ps(1) = '1' else    level1 & (1 downto 0 => '0');
   ----------------Synchro barrier, entering cycle 1----------------
   level3<=  (3 downto 0 => '0') & level2_d1 when ps_d1(2) = '1' else    level2_d1 & (3 downto 0 => '0');
   level4<=  (7 downto 0 => '0') & level3 when ps_d1(3) = '1' else    level3 & (7 downto 0 => '0');
   level5<=  (15 downto 0 => '0') & level4 when ps_d1(4) = '1' else    level4 & (15 downto 0 => '0');
   ----------------Synchro barrier, entering cycle 2----------------
   level6<=  (31 downto 0 => '0') & level5_d1 when ps_d2(5) = '1' else    level5_d1 & (31 downto 0 => '0');
   R <= level6(95 downto 28);
end architecture;

--------------------------------------------------------------------------------
--                    FPAdder_32_32_32_32_32_32_fracAddFar
--                               (IntAdder_36)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- and is distributed under the terms of the GNU Lesser General Public Licence.
-- Authors: Florent de Dinechin, Bogdan Pasca (2007, 2008)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;

entity FPAdder_32_32_32_32_32_32_fracAddFar is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(35 downto 0);
          Y : in  std_logic_vector(35 downto 0);
          Cin : in std_logic;
          R : out  std_logic_vector(35 downto 0)   );
end entity;

architecture arch of FPAdder_32_32_32_32_32_32_fracAddFar is
   signal X0 :  std_logic_vector(29 downto 0);
   signal Y0 :  std_logic_vector(29 downto 0);
   signal Carry : std_logic;
   signal X1 :  std_logic_vector(5 downto 0);
   signal Y1 :  std_logic_vector(5 downto 0);
   signal cin1R0 :  std_logic_vector(30 downto 0);
   signal cin1R0_d :  std_logic_vector(30 downto 0);
   signal R0 :  std_logic_vector(29 downto 0);
   signal R1 :  std_logic_vector(5 downto 0);
   signal sX0 :  std_logic_vector(29 downto 0);
   signal sY0 :  std_logic_vector(29 downto 0);
   signal cin0 : std_logic;
   signal sX1 :  std_logic_vector(5 downto 0);
   signal sX1_d :  std_logic_vector(5 downto 0);
   signal sY1 :  std_logic_vector(5 downto 0);
   signal sY1_d :  std_logic_vector(5 downto 0);
begin
   Carry <= Cin; 
   X0 <= X(29 downto 0);
   Y0 <= Y(29 downto 0);
   X1 <= X(35 downto 30);
   Y1 <= Y(35 downto 30);
   sX0 <= X0;
   sY0 <= Y0;
   cin0 <= Carry;
   sX1 <= X1;
   sY1 <= Y1;
   cin1R0 <= ("0" & sX0) + ("0" & sY0) + cin0;
   R0 <= cin1R0_d(29 downto 0);
   R1 <= sX1_d + sY1_d + cin1R0_d(30);
   R <= R1 & R0;

   process(clk)  begin
      if clk'event and clk = '1' then
         cin1R0_d <=  cin1R0;
         sX1_d <=  sX1;
         sY1_d <=  sY1;
      end if;
   end process;
end architecture;

--------------------------------------------------------------------------------
--                  FPAdder_32_32_32_32_32_32_finalRoundAdd
--                               (IntAdder_66)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- and is distributed under the terms of the GNU Lesser General Public Licence.
-- Authors: Florent de Dinechin, Bogdan Pasca (2007, 2008)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;

entity FPAdder_32_32_32_32_32_32_finalRoundAdd is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(65 downto 0);
          Y : in  std_logic_vector(65 downto 0);
          Cin : in std_logic;
          R : out  std_logic_vector(65 downto 0)   );
end entity;

architecture arch of FPAdder_32_32_32_32_32_32_finalRoundAdd is
   signal X0 :  std_logic_vector(29 downto 0);
   signal Y0 :  std_logic_vector(29 downto 0);
   signal Carry : std_logic;
   signal X1 :  std_logic_vector(28 downto 0);
   signal Y1 :  std_logic_vector(28 downto 0);
   signal X2 :  std_logic_vector(6 downto 0);
   signal Y2 :  std_logic_vector(6 downto 0);
   signal cin1R0 :  std_logic_vector(30 downto 0);
   signal cin1R0_d :  std_logic_vector(30 downto 0);
   signal cin2R1 :  std_logic_vector(29 downto 0);
   signal cin2R1_d :  std_logic_vector(29 downto 0);
   signal R0 :  std_logic_vector(29 downto 0);
   signal R0_d :  std_logic_vector(29 downto 0);
   signal R1 :  std_logic_vector(28 downto 0);
   signal R2 :  std_logic_vector(6 downto 0);
   signal sX0 :  std_logic_vector(29 downto 0);
   signal sY0 :  std_logic_vector(29 downto 0);
   signal cin0 : std_logic;
   signal sX1 :  std_logic_vector(28 downto 0);
   signal sX1_d :  std_logic_vector(28 downto 0);
   signal sY1 :  std_logic_vector(28 downto 0);
   signal sY1_d :  std_logic_vector(28 downto 0);
   signal sX2 :  std_logic_vector(6 downto 0);
   signal sX2_d :  std_logic_vector(6 downto 0);
   signal sX2_d_d :  std_logic_vector(6 downto 0);
   signal sY2 :  std_logic_vector(6 downto 0);
   signal sY2_d :  std_logic_vector(6 downto 0);
   signal sY2_d_d :  std_logic_vector(6 downto 0);
begin
   Carry <= Cin; 
   X0 <= X(29 downto 0);
   Y0 <= Y(29 downto 0);
   X1 <= X(58 downto 30);
   Y1 <= Y(58 downto 30);
   X2 <= X(65 downto 59);
   Y2 <= Y(65 downto 59);
   sX0 <= X0;
   sY0 <= Y0;
   cin0 <= Carry;
   sX1 <= X1;
   sY1 <= Y1;
   sX2 <= X2;
   sY2 <= Y2;
   cin1R0 <= ("0" & sX0) + ("0" & sY0) + cin0;
   cin2R1 <= ( "0" & sX1_d) + ( "0" & sY1_d) + cin1R0_d(30);
   R0 <= cin1R0_d(29 downto 0);
   R1 <= cin2R1_d(28 downto 0);
   R2 <= sX2_d_d + sY2_d_d + cin2R1_d(29);
   R <= R2 & R1 & R0_d;

   process(clk)  begin
      if clk'event and clk = '1' then
         cin1R0_d <=  cin1R0;
         cin2R1_d <=  cin2R1;
         R0_d <=  R0;
         sX1_d <=  sX1;
         sY1_d <=  sY1;
         sX2_d <=  sX2;
         sX2_d_d <=  sX2_d;
         sY2_d <=  sY2;
         sY2_d_d <=  sY2_d;
      end if;
   end process;
end architecture;

--------------------------------------------------------------------------------
--                         FPAdder_32_32_32_32_32_32
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- and is distributed under the terms of the GNU Lesser General Public Licence.
-- Authors: Bogdan Pasca, Florent de Dinechin (2008)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;

entity FPAdder_32_32_32_32_32_32 is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(32+32+2 downto 0);
          Y : in  std_logic_vector(32+32+2 downto 0);
          R : out  std_logic_vector(32+32+2 downto 0)   );
end entity;

architecture arch of FPAdder_32_32_32_32_32_32 is
   component FPAdder_32_32_32_32_32_32_DualSubClose is
      port ( clk, rst : in std_logic;
             X : in  std_logic_vector(34 downto 0);
             Y : in  std_logic_vector(34 downto 0);
             RxMy : out  std_logic_vector(34 downto 0);
             RyMx : out  std_logic_vector(34 downto 0)   );
   end component;

   component FPAdder_32_32_32_32_32_32_LZCShifter is
      port ( clk, rst : in std_logic;
             I : in  std_logic_vector(33 downto 0);
             Count : out  std_logic_vector(5 downto 0);
             O : out  std_logic_vector(33 downto 0)   );
   end component;

   component FPAdder_32_32_32_32_32_32_RightShifter is
      port ( clk, rst : in std_logic;
             X : in  std_logic_vector(32 downto 0);
             S : in  std_logic_vector(5 downto 0);
             R : out  std_logic_vector(67 downto 0)   );
   end component;

   component FPAdder_32_32_32_32_32_32_finalRoundAdd is
      port ( clk, rst : in std_logic;
             X : in  std_logic_vector(65 downto 0);
             Y : in  std_logic_vector(65 downto 0);
             Cin : in std_logic;
             R : out  std_logic_vector(65 downto 0)   );
   end component;

   component FPAdder_32_32_32_32_32_32_fracAddFar is
      port ( clk, rst : in std_logic;
             X : in  std_logic_vector(35 downto 0);
             Y : in  std_logic_vector(35 downto 0);
             Cin : in std_logic;
             R : out  std_logic_vector(35 downto 0)   );
   end component;

signal inX :  std_logic_vector(66 downto 0);
signal inY :  std_logic_vector(66 downto 0);
signal exceptionXSuperiorY : std_logic;
signal exceptionXEqualY : std_logic;
signal signedExponentX :  std_logic_vector(32 downto 0);
signal signedExponentY :  std_logic_vector(32 downto 0);
signal exponentDifferenceXY :  std_logic_vector(32 downto 0);
signal exponentDifferenceYX :  std_logic_vector(31 downto 0);
signal swap : std_logic;
signal newX, newX_d1, newX_d2, newX_d3, newX_d4, newX_d5, newX_d6, newX_d7, newX_d8, newX_d9, newX_d10, newX_d11, newX_d12, newX_d13, newX_d14 :  std_logic_vector(66 downto 0);
signal newY, newY_d1 :  std_logic_vector(66 downto 0);
signal exponentDifference, exponentDifference_d1 :  std_logic_vector(31 downto 0);
signal shiftedOut : std_logic;
signal shiftVal, shiftVal_d1 :  std_logic_vector(5 downto 0);
signal EffSub, EffSub_d1, EffSub_d2, EffSub_d3, EffSub_d4, EffSub_d5, EffSub_d6, EffSub_d7, EffSub_d8, EffSub_d9, EffSub_d10, EffSub_d11, EffSub_d12, EffSub_d13 : std_logic;
signal selectClosePath, selectClosePath_d1, selectClosePath_d2, selectClosePath_d3, selectClosePath_d4, selectClosePath_d5, selectClosePath_d6, selectClosePath_d7, selectClosePath_d8, selectClosePath_d9, selectClosePath_d10 : std_logic;
signal sdExnXY, sdExnXY_d1, sdExnXY_d2, sdExnXY_d3, sdExnXY_d4, sdExnXY_d5, sdExnXY_d6, sdExnXY_d7, sdExnXY_d8, sdExnXY_d9, sdExnXY_d10, sdExnXY_d11, sdExnXY_d12, sdExnXY_d13 :  std_logic_vector(3 downto 0);
signal pipeSignY, pipeSignY_d1, pipeSignY_d2, pipeSignY_d3, pipeSignY_d4, pipeSignY_d5, pipeSignY_d6, pipeSignY_d7, pipeSignY_d8, pipeSignY_d9, pipeSignY_d10, pipeSignY_d11, pipeSignY_d12, pipeSignY_d13 : std_logic;
signal fracXClose1 :  std_logic_vector(34 downto 0);
signal fracYClose1 :  std_logic_vector(34 downto 0);
signal fracRClosexMy, fracRClosexMy_d1 :  std_logic_vector(34 downto 0);
signal fracRCloseyMx, fracRCloseyMx_d1 :  std_logic_vector(34 downto 0);
signal fracSignClose : std_logic;
signal fracRClose1 :  std_logic_vector(33 downto 0);
signal resSign, resSign_d1, resSign_d2, resSign_d3, resSign_d4, resSign_d5, resSign_d6, resSign_d7, resSign_d8, resSign_d9, resSign_d10, resSign_d11 : std_logic;
signal nZerosNew, nZerosNew_d1 :  std_logic_vector(5 downto 0);
signal shiftedFrac, shiftedFrac_d1, shiftedFrac_d2 :  std_logic_vector(33 downto 0);
signal roundClose0, roundClose0_d1 : std_logic;
signal resultCloseIsZero0, resultCloseIsZero0_d1 : std_logic;
signal exponentResultClose, exponentResultClose_d1 :  std_logic_vector(33 downto 0);
signal resultBeforeRoundClose :  std_logic_vector(65 downto 0);
signal roundClose : std_logic;
signal resultCloseIsZero : std_logic;
signal fracNewY :  std_logic_vector(32 downto 0);
signal shiftedFracY, shiftedFracY_d1, shiftedFracY_d2 :  std_logic_vector(67 downto 0);
signal sticky, sticky_d1, sticky_d2, sticky_d3 : std_logic;
signal fracYfar :  std_logic_vector(35 downto 0);
signal fracYfarXorOp :  std_logic_vector(35 downto 0);
signal fracXfar :  std_logic_vector(35 downto 0);
signal cInAddFar : std_logic;
signal fracResultfar0, fracResultfar0_d1 :  std_logic_vector(35 downto 0);
signal fracResultFarNormStage :  std_logic_vector(35 downto 0);
signal fracLeadingBits :  std_logic_vector(1 downto 0);
signal fracResultFar1, fracResultFar1_d1 :  std_logic_vector(31 downto 0);
signal fracResultRoundBit : std_logic;
signal fracResultStickyBit : std_logic;
signal roundFar1, roundFar1_d1 : std_logic;
signal expOperationSel :  std_logic_vector(1 downto 0);
signal exponentUpdate :  std_logic_vector(33 downto 0);
signal exponentResultfar0 :  std_logic_vector(33 downto 0);
signal exponentResultFar1, exponentResultFar1_d1 :  std_logic_vector(33 downto 0);
signal resultBeforeRoundFar, resultBeforeRoundFar_d1, resultBeforeRoundFar_d2, resultBeforeRoundFar_d3 :  std_logic_vector(65 downto 0);
signal roundFar, roundFar_d1, roundFar_d2, roundFar_d3 : std_logic;
signal syncClose : std_logic;
signal resultBeforeRound :  std_logic_vector(65 downto 0);
signal round : std_logic;
signal zeroFromClose, zeroFromClose_d1, zeroFromClose_d2, zeroFromClose_d3 : std_logic;
signal resultRounded, resultRounded_d1 :  std_logic_vector(65 downto 0);
signal syncEffSub : std_logic;
signal syncX :  std_logic_vector(66 downto 0);
signal syncSignY : std_logic;
signal syncResSign : std_logic;
signal UnderflowOverflow :  std_logic_vector(1 downto 0);
signal resultNoExn :  std_logic_vector(66 downto 0);
signal syncExnXY :  std_logic_vector(3 downto 0);
signal exnR :  std_logic_vector(1 downto 0);
signal sgnR : std_logic;
signal expsigR :  std_logic_vector(63 downto 0);
begin
   process(clk)  begin
      if clk'event and clk = '1' then
         newX_d1 <=  newX;
         newX_d2 <=  newX_d1;
         newX_d3 <=  newX_d2;
         newX_d4 <=  newX_d3;
         newX_d5 <=  newX_d4;
         newX_d6 <=  newX_d5;
         newX_d7 <=  newX_d6;
         newX_d8 <=  newX_d7;
         newX_d9 <=  newX_d8;
         newX_d10 <=  newX_d9;
         newX_d11 <=  newX_d10;
         newX_d12 <=  newX_d11;
         newX_d13 <=  newX_d12;
         newX_d14 <=  newX_d13;
         newY_d1 <=  newY;
         exponentDifference_d1 <=  exponentDifference;
         shiftVal_d1 <=  shiftVal;
         EffSub_d1 <=  EffSub;
         EffSub_d2 <=  EffSub_d1;
         EffSub_d3 <=  EffSub_d2;
         EffSub_d4 <=  EffSub_d3;
         EffSub_d5 <=  EffSub_d4;
         EffSub_d6 <=  EffSub_d5;
         EffSub_d7 <=  EffSub_d6;
         EffSub_d8 <=  EffSub_d7;
         EffSub_d9 <=  EffSub_d8;
         EffSub_d10 <=  EffSub_d9;
         EffSub_d11 <=  EffSub_d10;
         EffSub_d12 <=  EffSub_d11;
         EffSub_d13 <=  EffSub_d12;
         selectClosePath_d1 <=  selectClosePath;
         selectClosePath_d2 <=  selectClosePath_d1;
         selectClosePath_d3 <=  selectClosePath_d2;
         selectClosePath_d4 <=  selectClosePath_d3;
         selectClosePath_d5 <=  selectClosePath_d4;
         selectClosePath_d6 <=  selectClosePath_d5;
         selectClosePath_d7 <=  selectClosePath_d6;
         selectClosePath_d8 <=  selectClosePath_d7;
         selectClosePath_d9 <=  selectClosePath_d8;
         selectClosePath_d10 <=  selectClosePath_d9;
         sdExnXY_d1 <=  sdExnXY;
         sdExnXY_d2 <=  sdExnXY_d1;
         sdExnXY_d3 <=  sdExnXY_d2;
         sdExnXY_d4 <=  sdExnXY_d3;
         sdExnXY_d5 <=  sdExnXY_d4;
         sdExnXY_d6 <=  sdExnXY_d5;
         sdExnXY_d7 <=  sdExnXY_d6;
         sdExnXY_d8 <=  sdExnXY_d7;
         sdExnXY_d9 <=  sdExnXY_d8;
         sdExnXY_d10 <=  sdExnXY_d9;
         sdExnXY_d11 <=  sdExnXY_d10;
         sdExnXY_d12 <=  sdExnXY_d11;
         sdExnXY_d13 <=  sdExnXY_d12;
         pipeSignY_d1 <=  pipeSignY;
         pipeSignY_d2 <=  pipeSignY_d1;
         pipeSignY_d3 <=  pipeSignY_d2;
         pipeSignY_d4 <=  pipeSignY_d3;
         pipeSignY_d5 <=  pipeSignY_d4;
         pipeSignY_d6 <=  pipeSignY_d5;
         pipeSignY_d7 <=  pipeSignY_d6;
         pipeSignY_d8 <=  pipeSignY_d7;
         pipeSignY_d9 <=  pipeSignY_d8;
         pipeSignY_d10 <=  pipeSignY_d9;
         pipeSignY_d11 <=  pipeSignY_d10;
         pipeSignY_d12 <=  pipeSignY_d11;
         pipeSignY_d13 <=  pipeSignY_d12;
         fracRClosexMy_d1 <=  fracRClosexMy;
         fracRCloseyMx_d1 <=  fracRCloseyMx;
         resSign_d1 <=  resSign;
         resSign_d2 <=  resSign_d1;
         resSign_d3 <=  resSign_d2;
         resSign_d4 <=  resSign_d3;
         resSign_d5 <=  resSign_d4;
         resSign_d6 <=  resSign_d5;
         resSign_d7 <=  resSign_d6;
         resSign_d8 <=  resSign_d7;
         resSign_d9 <=  resSign_d8;
         resSign_d10 <=  resSign_d9;
         resSign_d11 <=  resSign_d10;
         nZerosNew_d1 <=  nZerosNew;
         shiftedFrac_d1 <=  shiftedFrac;
         shiftedFrac_d2 <=  shiftedFrac_d1;
         roundClose0_d1 <=  roundClose0;
         resultCloseIsZero0_d1 <=  resultCloseIsZero0;
         exponentResultClose_d1 <=  exponentResultClose;
         shiftedFracY_d1 <=  shiftedFracY;
         shiftedFracY_d2 <=  shiftedFracY_d1;
         sticky_d1 <=  sticky;
         sticky_d2 <=  sticky_d1;
         sticky_d3 <=  sticky_d2;
         fracResultfar0_d1 <=  fracResultfar0;
         fracResultFar1_d1 <=  fracResultFar1;
         roundFar1_d1 <=  roundFar1;
         exponentResultFar1_d1 <=  exponentResultFar1;
         resultBeforeRoundFar_d1 <=  resultBeforeRoundFar;
         resultBeforeRoundFar_d2 <=  resultBeforeRoundFar_d1;
         resultBeforeRoundFar_d3 <=  resultBeforeRoundFar_d2;
         roundFar_d1 <=  roundFar;
         roundFar_d2 <=  roundFar_d1;
         roundFar_d3 <=  roundFar_d2;
         zeroFromClose_d1 <=  zeroFromClose;
         zeroFromClose_d2 <=  zeroFromClose_d1;
         zeroFromClose_d3 <=  zeroFromClose_d2;
         resultRounded_d1 <=  resultRounded;
      end if;
   end process;
-- Exponent difference and swap  --
   inX <= X;
   inY <= Y;
   exceptionXSuperiorY <= '1' when inX(66 downto 65) >= inY(66 downto 65) else '0';
   exceptionXEqualY <= '1' when inX(66 downto 65) = inY(66 downto 65) else '0';
   signedExponentX <= "0" & inX(63 downto 32);
   signedExponentY <= "0" & inY(63 downto 32);
   exponentDifferenceXY <= signedExponentX - signedExponentY ;
   exponentDifferenceYX <= signedExponentY(31 downto 0) - signedExponentX(31 downto 0);
   swap <= (exceptionXEqualY and exponentDifferenceXY(32)) or (not(exceptionXSuperiorY));
   newX <= inY when swap = '1' else inX;
   newY <= inX when swap = '1' else inY;
   exponentDifference <= exponentDifferenceYX when swap = '1' else exponentDifferenceXY(31 downto 0);
   shiftedOut <= exponentDifference(31) or exponentDifference(30) or exponentDifference(29) or exponentDifference(28) or exponentDifference(27) or exponentDifference(26) or exponentDifference(25) or exponentDifference(24) or exponentDifference(23) or exponentDifference(22) or exponentDifference(21) or exponentDifference(20) or exponentDifference(19) or exponentDifference(18) or exponentDifference(17) or exponentDifference(16) or exponentDifference(15) or exponentDifference(14) or exponentDifference(13) or exponentDifference(12) or exponentDifference(11) or exponentDifference(10) or exponentDifference(9) or exponentDifference(8) or exponentDifference(7) or exponentDifference(6);
   shiftVal <= exponentDifference(5 downto 0) when shiftedOut='0'
          else CONV_STD_LOGIC_VECTOR(35,6) ;
   ----------------Synchro barrier, entering cycle 1----------------
   EffSub <= newX_d1(64) xor newY_d1(64);
   selectClosePath <= EffSub when exponentDifference_d1(31 downto 1) = (31 downto 1 => '0') else '0';
   sdExnXY <= newX_d1(66 downto 65) & newY_d1(66 downto 65);
   pipeSignY <= newY_d1(64);

-- Close Path --
   fracXClose1 <= "01" & newX_d1(31 downto 0) & '0';
   with exponentDifference_d1(0) select
   fracYClose1 <=  "01" & newY_d1(31 downto 0) & '0' when '0',
                  "001" & newY_d1(31 downto 0)       when others;
   DualSubO: FPAdder_32_32_32_32_32_32_DualSubClose  -- pipelineDepth=1
      port map ( clk  => clk, 
                 rst  => rst, 
                 RxMy => fracRClosexMy,
                 RyMx => fracRCloseyMx,
                 X => fracXClose1,
                 Y => fracYClose1);
   ----------------Synchro barrier, entering cycle 2----------------
   ----------------Synchro barrier, entering cycle 3----------------
   fracSignClose <= fracRClosexMy_d1(34);
   fracRClose1 <= fracRClosexMy_d1(33 downto 0) when fracSignClose='0' else fracRCloseyMx_d1(33 downto 0);
   resSign <= '0' when selectClosePath_d2='1' and fracRClose1 = (33 downto 0 => '0') else
             newX_d3(64) xor (selectClosePath_d2 and fracSignClose);
   LZC_component: FPAdder_32_32_32_32_32_32_LZCShifter  -- pipelineDepth=6
      port map ( clk  => clk, 
                 rst  => rst, 
                 Count => nZerosNew,
                 I => fracRClose1,
                 O => shiftedFrac);
   ----------------Synchro barrier, entering cycle 9----------------
   ----------------Synchro barrier, entering cycle 10----------------
   roundClose0 <= shiftedFrac_d1(0) and shiftedFrac_d1(1);
   resultCloseIsZero0 <= '1' when nZerosNew_d1 = CONV_STD_LOGIC_VECTOR(34, 6) else '0';
   exponentResultClose <= ("00" & newX_d10(63 downto 32)) - (CONV_STD_LOGIC_VECTOR(0,28) & nZerosNew_d1);
   ----------------Synchro barrier, entering cycle 11----------------
   resultBeforeRoundClose <= exponentResultClose_d1(33 downto 0) & shiftedFrac_d2(32 downto 1);
   roundClose <= roundClose0_d1;
   resultCloseIsZero <= resultCloseIsZero0_d1;

-- Far Path --
   fracNewY <= '1' & newY_d1(31 downto 0);
   RightShifterComponent: FPAdder_32_32_32_32_32_32_RightShifter  -- pipelineDepth=2
      port map ( clk  => clk, 
                 rst  => rst, 
                 R => shiftedFracY,
                 S => shiftVal_d1,
                 X => fracNewY);
   ----------------Synchro barrier, entering cycle 3----------------
   ----------------Synchro barrier, entering cycle 4----------------
   sticky <= '0' when (shiftedFracY_d1(32 downto 0)=CONV_STD_LOGIC_VECTOR(0,32)) else '1';
   ----------------Synchro barrier, entering cycle 5----------------
   fracYfar <= "0" & shiftedFracY_d2(67 downto 33);
   fracYfarXorOp <= fracYfar xor (35 downto 0 => EffSub_d4);
   fracXfar <= "01" & (newX_d5(31 downto 0)) & "00";
   cInAddFar <= EffSub_d4 and not sticky_d1;
   fracAdderFar: FPAdder_32_32_32_32_32_32_fracAddFar  -- pipelineDepth=1
      port map ( clk  => clk, 
                 rst  => rst, 
                 Cin => cInAddFar,
                 R => fracResultfar0,
                 X => fracXfar,
                 Y => fracYfarXorOp);
   ----------------Synchro barrier, entering cycle 6----------------
   ----------------Synchro barrier, entering cycle 7----------------
   -- 2-bit normalisation
   fracResultFarNormStage <= fracResultfar0_d1;
   fracLeadingBits <= fracResultFarNormStage(35 downto 34) ;
   fracResultFar1 <=
           fracResultFarNormStage(32 downto 1)  when fracLeadingBits = "00" 
      else fracResultFarNormStage(33 downto 2)  when fracLeadingBits = "01" 
      else fracResultFarNormStage(34 downto 3);
   fracResultRoundBit <=
           fracResultFarNormStage(0) 	 when fracLeadingBits = "00" 
      else fracResultFarNormStage(1)    when fracLeadingBits = "01" 
      else fracResultFarNormStage(2) ;
   fracResultStickyBit <=
           sticky_d3 	 when fracLeadingBits = "00" 
      else fracResultFarNormStage(0) or  sticky_d3   when fracLeadingBits = "01" 
      else fracResultFarNormStage(1) or fracResultFarNormStage(0) or sticky_d3;
   roundFar1 <= fracResultRoundBit and (fracResultStickyBit or fracResultFar1(0));
   expOperationSel <= "11" when fracLeadingBits = "00" -- add -1 to exponent
               else   "00" when fracLeadingBits = "01" -- add 0 
               else   "01";                              -- add 1
   exponentUpdate <= (33 downto 1 => expOperationSel(1)) & expOperationSel(0);
   exponentResultfar0<="00" & (newX_d7(63 downto 32));
   exponentResultFar1 <= exponentResultfar0 + exponentUpdate;
   ----------------Synchro barrier, entering cycle 8----------------
   resultBeforeRoundFar <= exponentResultFar1_d1 & fracResultFar1_d1;
   roundFar <= roundFar1_d1;

-- Synchronization of both paths --
   ----------------Synchro barrier, entering cycle 11----------------
   syncClose <= selectClosePath_d10;
   with syncClose select
   resultBeforeRound <= resultBeforeRoundClose when '1',
                        resultBeforeRoundFar_d3   when others;
   with syncClose select
   round <= roundClose when '1',
            roundFar_d3   when others;
   zeroFromClose <= syncClose and resultCloseIsZero;

-- Rounding --
   finalRoundAdder: FPAdder_32_32_32_32_32_32_finalRoundAdd  -- pipelineDepth=2
      port map ( clk  => clk, 
                 rst  => rst, 
                 Cin => round,
                 R => resultRounded,
                 X => resultBeforeRound,
                 Y => (65 downto 0 => '0') );
   ----------------Synchro barrier, entering cycle 13----------------
   ----------------Synchro barrier, entering cycle 14----------------
   syncEffSub <= EffSub_d13;
   syncX <= newX_d14;
   syncSignY <= pipeSignY_d13;
   syncResSign <= resSign_d11;
   UnderflowOverflow <= resultRounded_d1(65 downto 64);
   with UnderflowOverflow select
   resultNoExn(66 downto 65) <=   (not zeroFromClose_d3) & "0" when "01", -- overflow
                                 "00" when "10" | "11",  -- underflow
                                 "0" &  not zeroFromClose_d3  when others; -- normal 
   resultNoExn(64 downto 0) <= syncResSign & resultRounded_d1(63 downto 0);
   syncExnXY <= sdExnXY_d13;
   -- Exception bits of the result
   with syncExnXY select -- remember that ExnX > ExnY 
      exnR <= resultNoExn(66 downto 65) when "0101",
              "1" & syncEffSub          when "1010",
              "11"                      when "1110",
              syncExnXY(3 downto 2)     when others;
   -- Sign bit of the result
   with syncExnXY select
      sgnR <= resultNoExn(64)         when "0101",
              syncX(64) and syncSignY when "0000",
              syncX(64)               when others;
   -- Exponent and significand of the result
   with syncExnXY select  
      expsigR <= resultNoExn(63 downto 0)   when "0101" ,
                 syncX(63 downto  0)        when others; -- 0100, or at least one NaN or one infty 
   R <= exnR & sgnR & expsigR;
end architecture;

--------------------------------------------------------------------------------
--                                    dupa
--                    (FPAdder_32_32_32_32_32_32_Wrapper)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- and is distributed under the terms of the GNU Lesser General Public Licence.
-- Authors: Florent de Dinechin (2007)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;

entity dupa is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(32+32+2 downto 0);
          Y : in  std_logic_vector(32+32+2 downto 0);
          R : out  std_logic_vector(32+32+2 downto 0)   );
end entity;

architecture arch of dupa is
   component FPAdder_32_32_32_32_32_32 is
      port ( clk, rst : in std_logic;
             X : in  std_logic_vector(32+32+2 downto 0);
             Y : in  std_logic_vector(32+32+2 downto 0);
             R : out  std_logic_vector(32+32+2 downto 0)   );
   end component;
   signal i_X :  std_logic_vector(66 downto 0);
   signal i_X_d :  std_logic_vector(66 downto 0);
   signal i_Y :  std_logic_vector(66 downto 0);
   signal i_Y_d :  std_logic_vector(66 downto 0);
   signal i_R :  std_logic_vector(66 downto 0);
   signal i_R_d :  std_logic_vector(66 downto 0);
begin
--wrapper operator
   i_X <=  X;
   i_Y <=  Y;
   test:FPAdder_32_32_32_32_32_32
      port map (       clk => clk, 
      rst => rst, 
X =>  i_X_d,
                 Y =>  i_Y_d,
                 R =>  i_R);
   process(clk)  begin
      if clk'event and clk = '1' then
         i_X_d <=  i_X;
         i_Y_d <=  i_Y;
         i_R_d <=  i_R;
      end if;
   end process;
   R <=  i_R_d;
end architecture;

