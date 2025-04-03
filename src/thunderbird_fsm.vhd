--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 xxx State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 10000000
--|                  ON    | 01111111
--|                  R1    | 00000001
--|                  R2    | 00000011
--|                  R3    | 00000111
--|                  L1    | 00001000
--|                  L2    | 00011000
--|                  L3    | 00111000
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is 
  port(
  i_clk, i_reset  : in    std_logic;
  i_left, i_right : in    std_logic;
  o_lights_L      : out   std_logic_vector(2 downto 0);
  o_lights_R      : out   std_logic_vector(2 downto 0)	
  );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 

signal f_Q      : std_logic_vector(7 downto 0) := "10000000";
signal f_Q_next : std_logic_vector(7 downto 0) := "10000000";
--signal i_lr     : std_logic_vector(1 downto 0) := "00";

-- CONSTANTS ------------------------------------------------------------------
  
begin

	-- CONCURRENT STATEMENTS --------------------------------------------------------		
	-- next state :  
  f_Q_next(7) <= (f_Q(7) and not i_left and not i_right) -- off ~l~r -> off (stay off)
	            or  f_Q(6)                                 -- on       -> off (haz blink off)
              or  f_Q(2)          -- r3 -> off (r end)
	            or  f_Q(5);         -- l3 -> off (l end)
	
  f_Q_next(0) <= f_Q(7) and not i_left and     i_right; -- off ~l r -> r1  (r start)
	f_Q_next(3) <= f_Q(7) and     i_left and not i_right; -- off  l~r -> l1  (l start)
  f_Q_next(6) <= f_Q(7) and     i_left and     i_right; -- off  l r -> on  (haz blink on)
	f_Q_next(1) <= f_Q(0); -- r1 -> r2  (r adv)
	f_Q_next(2) <= f_Q(1); -- r2 -> r3  (r adv) 
	f_Q_next(4) <= f_Q(3); -- l1 -> l2  (l adv)
	f_Q_next(5) <= f_Q(4); -- l2 -> l3  (l adv)
	
	-- outputs
	with f_Q select
	o_lights_R <= "000" when "10000000", -- turn all lights off if OFF
	              "111" when "01000000", -- turn all lights on if ON
                "001" when "00000001", -- r1
	              "011" when "00000010", -- r2 
	              "111" when "00000100", -- r3
	              "000" when others;     -- like while right sig is happening
	
	with f_Q select
	o_lights_L <= "000" when "10000000", -- OFF
	              "111" when "01000000", -- ON
	              "001" when "00001000", -- l1
	              "011" when "00010000", -- l2
	              "111" when "00100000", -- l3
	              "000" when others;     -- like while left sig is happening
	
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
  register_proc : process (i_clk, i_reset)
	begin
    if i_reset = '1' then
       f_Q <= "10000000";  -- reset state is yellow
    elsif (rising_edge(i_clk)) then
       f_Q <= f_Q_next;    -- next state becomes current state
    end if;
  end process register_proc;
	-----------------------------------------------------					   
				  
end thunderbird_fsm_arch;
