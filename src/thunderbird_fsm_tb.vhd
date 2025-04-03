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
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
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
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
  	  port(
  	  i_clk, i_reset  : in    std_logic;
      i_left, i_right : in    std_logic;
      o_lights_L      : out   std_logic_vector(2 downto 0);
      o_lights_R      : out   std_logic_vector(2 downto 0)	
  	  );
	end component;

	-- test I/O signals
	-- in
	signal w_clk, w_reset  : std_logic := '0';
	signal w_left, w_right : std_logic := '0';
	-- out
	signal w_lights        : std_logic_vector(5 downto 0) := "000000";
	-- constants
	constant k_clk_period  : time := 10 ns;	
	
begin
	-- PORT MAPS ----------------------------------------
	-- unit under test
	uut: thunderbird_fsm port map(
	  i_clk      => w_clk,
	  i_reset    => w_reset,
	  i_left     => w_left,
	  i_right    => w_right,
	  o_lights_L => w_lights(5 downto 3),
	  o_lights_R => w_lights(2 downto 0)
	);
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    	clk_proc : process
	begin
		w_clk <= '0';
        wait for k_clk_period/2;
		w_clk <= '1';
		wait for k_clk_period/2;
	end process;
	
	-- Simulation process
	sim_proc: process
	begin
	-- sequential timing		
	w_reset <= '1'; wait for k_clk_period*1; w_reset <= '0'; wait for k_clk_period;
	  assert w_lights = "000000" report "bad reset" severity failure;
		
	-- set up lr : left off, right off
	w_left  <= '0'; w_right <= '0'; wait for k_clk_period;

	  assert w_lights = "000000" report "lights not off when l'r'" severity failure;
	-- left on
  w_left <= '1'; wait for k_clk_period;
    assert w_lights = "001000" report "l1 should be on right after left turn on" severity failure;
  wait for k_clk_period * 3; -- watch left sequence until off again
    assert w_lights = "000000" report "should be off after first left seq" severity failure;
	wait for k_clk_period * 2; -- wait for middle of left seq
        -- left off
	w_left <= '0';  -- left off; make sure it does not shut off seq until next off
	wait for k_clk_period * 4; -- wait a bit it should stay off after seq
	  assert w_lights = "000000" report "left should have stayed off after seq if l'"
	       severity failure;
        
	-- right on
	w_right <= '1'; wait for k_clk_period;
    assert w_lights = "000001" report "r1 should be on right after right turn on" severity failure;
  wait for k_clk_period * 3; -- watch right sequence until off again
    assert w_lights = "000000" report "should be off after first right seq" severity failure;
	wait for k_clk_period * 2; -- wait for middle of right seq
  -- right off
	w_right <= '0';  -- right off; make sure it does not shut off seq until next off 
	wait for k_clk_period * 4; -- wait a bit it should stay off after seq
	  assert w_lights = "000000" report "right should have stayed off after seq if r'"
	  severity failure;
        
  -- res during left ts
  w_left <= '1'; wait for k_clk_period*2;
	w_reset <= '1'; wait for k_clk_period; w_reset <= '0'; wait for k_clk_period;
    assert w_lights = "001000" report "bad reset during ts blink" severity failure;
  -- watch ts, should start over and go for 6 clk per
    wait for k_clk_period*5; -- watch it blink, should blink
  w_left <= '0'; wait for k_clk_period*3; -- move on
  
  -- haz on
  w_left <= '1'; w_right <= '1'; wait for k_clk_period;
	  assert w_lights = "111111" report "bad haz on" severity failure;
	wait for k_clk_period * 8; -- watch haz seq
	w_left <= '0'; w_right <= '0'; wait for k_clk_period;
	  assert w_lights = "000000" report "bad haz off" severity failure;
	
	  wait;
	end process;

end test_bench;
