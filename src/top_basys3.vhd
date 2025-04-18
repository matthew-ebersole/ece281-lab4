library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    constant cf : std_logic_vector(3 downto 0) := "1111";
    constant SEG_LIMIT : natural := 50000;
    constant CLK_DIV   : natural := 25000000;

    signal clk_slow : std_logic;
    signal clk_tdm : std_logic;
    signal tdm_count : unsigned(16 downto 0) := (others => '0');
    signal floor1, floor2 : std_logic_vector(3 downto 0);
    signal tdm_out : std_logic_vector(3 downto 0);
    signal tdm_sel : std_logic_vector(3 downto 0);
    signal clk_reset, fsm_reset : std_logic;

    -- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4);
        Port (
            i_clk      : in  STD_LOGIC;
            i_reset    : in  STD_LOGIC;
            i_D3       : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D2       : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D1       : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D0       : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_data     : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_sel      : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component TDM4;
         
    component elevator_controller_fsm is
        Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)           
         );
    end component elevator_controller_fsm;
    
    component clock_divider is
        generic ( constant k_DIV : natural := 25000000 );
        port ( 
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            o_clk    : out std_logic
        );
    end component clock_divider;

begin
    -- PORT MAPS ----------------------------------------
    clk_reset <= btnU or btnL;
    fsm_reset <= btnU or btnR;

    clk_divider_inst: clock_divider
        generic map (k_DIV => CLK_DIV)
        port map(
            i_clk => clk,
            i_reset => clk_reset,
            o_clk => clk_slow
        );

    clk_divider_tdm: clock_divider
        generic map (k_DIV => SEG_LIMIT)
        port map(
            i_clk   => clk,
            i_reset => clk_reset,
            o_clk   => clk_tdm
        );

    fsm_inst1: elevator_controller_fsm
        port map(
            i_clk => clk_slow,
            i_reset => fsm_reset,
            is_stopped => sw(0),
            go_up_down => sw(1),
            o_floor => floor1
        );

    fsm_inst2: elevator_controller_fsm
        port map(
            i_clk => clk_slow,
            i_reset => fsm_reset,
            is_stopped => sw(14),
            go_up_down => sw(15),
            o_floor => floor2
        );

    tdm4_inst: TDM4
        generic map ( k_WIDTH => 4 )
        port map(
            i_clk => clk_tdm,
            i_reset => btnU,
            i_D3 => cf,
            i_D2 => floor2,
            i_D1 => cf,
            i_D0 => floor1,
            o_data => tdm_out,
            o_sel => tdm_sel
        );

    seg_decoder_inst: sevenseg_decoder
        port map(
            i_Hex => tdm_out,
            o_seg_n => seg
        );

    -- CONCURRENT STATEMENTS ----------------------------
    an <= tdm_sel;
    led(15) <= clk_slow;
    led(3 downto 0) <= floor1;
    led(7 downto 4) <= floor2;
    led(14 downto 8) <= (others => '0');
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
end top_basys3_arch;
