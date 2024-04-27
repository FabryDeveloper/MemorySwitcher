----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Fabrizio Sordetti
-- 
-- Create Date: 06.02.2023 12:23:03
-- Design Name: 10730069
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 10730069
-- Target Devices: 
-- Tool Versions: 1.0
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_w : in std_logic;
        o_z0 : out std_logic_vector(7 downto 0);
        o_z1 : out std_logic_vector(7 downto 0);
        o_z2 : out std_logic_vector(7 downto 0);
        o_z3 : out std_logic_vector(7 downto 0);
        o_done : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_we : out std_logic;
        o_mem_en : out std_logic
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
signal wParallel: std_logic_vector(17 downto 0);
signal memOut: std_logic_vector(7 downto 0);
signal wDone, memDone: std_logic;

component serialToParallel is
    port( 
        in1 : in std_logic;
        clk, start, rst: in std_logic;
        out1 : out std_logic_vector(17 downto 0);
        done : out std_logic
    );
end component;

component memoryInterface is
    port(
        wParallel : in std_logic_vector(17 downto 0);
        wDone, clk, rst: in std_logic;
        mem_data : in std_logic_vector(7 downto 0);
        mem_en, mem_we, done: out std_logic;
        addr : out std_logic_vector(15 downto 0);
        memOut : out std_logic_vector(7 downto 0)
    );
end component;

component outSwitcher is
    port(
        wParallel : in std_logic_vector(17 downto 0);
        memOut : in std_logic_vector(7 downto 0);
        memDone, clk, rst : in std_logic;
        o_z0, o_z1, o_z2, o_z3 : out std_logic_vector(7 downto 0);
        done: out std_logic
    );
end component;

begin
    sToP : serialToParallel
        port map(in1 => i_w, clk => i_clk, start => i_start, 
                rst => i_rst, out1 => wParallel, done => wDone);
    memI : memoryInterface
        port map(wParallel => wParallel, wDone => wDone, clk => i_clk, rst => i_rst,
                mem_data => i_mem_data, mem_en => o_mem_en, mem_we => o_mem_we, 
                done => memDone, addr => o_mem_addr, memOut => memOut);
    switch : outSwitcher
        port map(wParallel => wParallel, memOut => memOut, memDone => memDone, clk => i_clk, rst => i_rst,
                o_z0 => o_z0, o_z1 => o_z1, o_z2 => o_z2, o_z3 => o_z3, done => o_done);
            
end Behavioral;

----------------- serialToParallel -----------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity serialToParallel is
    port( 
        in1 : in std_logic;
        clk, start, rst: in std_logic;
        out1 : out std_logic_vector(17 downto 0);
        done : out std_logic
    );
end serialToParallel;

architecture Behavioral of serialToParallel is
signal oldStart, oldStartX2 : std_logic;

signal interOut : std_logic_vector(17 downto 0);

begin
    CONVERSION_SERIAL_TO_PARALLEL: process(clk, rst)
    variable tmp : std_logic_vector(17 downto 0);
    variable rising_edge_start, interDone : std_logic;
    begin
        if (rst = '1') then
                oldStart <= '0';
                oldStartX2 <= '0';
                
                rising_edge_start := '0';
                interDone :='0';
        elsif rising_edge(clk) then
            
            oldStartX2 <= oldStart;    
            oldStart <= start;
                
            rising_edge_start := start and (not(oldStart) or not(oldStartX2));
            interDone := (oldStart and (not(start))) or (interDone and not(start));
            
            if rising_edge_start = '1' then
                tmp := interOut;
                tmp(17) := tmp(16);
                tmp(16) := in1;
                tmp(15 downto 0) := (others => '0');
            else
                tmp := interOut;
                if start= '1' then
                    tmp(15 downto 1) := tmp(14 downto 0);
                    tmp(0) := in1;
                end if;
            end if;
            
            out1 <= tmp;
            interOut <= tmp;
            done <= interDone;
            
        end if;
        
    end process;
    
end Behavioral;

----------------- memoryInterface -----------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity memoryInterface is
    port(
        wParallel : in std_logic_vector(17 downto 0);
        wDone, clk, rst: in std_logic;
        mem_data : in std_logic_vector(7 downto 0);
        mem_en, mem_we, done: out std_logic;
        addr : out std_logic_vector(15 downto 0);
        memOut : out std_logic_vector(7 downto 0)
    );
end memoryInterface;

architecture Behavioral of memoryInterface is
signal oldDone : std_logic;

begin
    
    SET_IN_MEMORY : process (wDone)
    begin
        if wDone = '1' then
            addr <= wParallel(15 downto 0);
            mem_en <= '1';
            mem_we <= '0';
        else
            addr <= (others => '0');
            mem_en <= '0';
            mem_we <= '0';
        end if;
    end process;
    
    RECIVE_OUT_MEMORY : process(clk, rst)
    variable rising_edge_done : std_logic;

    begin
        if (rst = '1') then
            oldDone <= '0';
                
            rising_edge_done := '0';
            done <='0';
            memOut <= (others => '0');
            
        elsif rising_edge(clk) then

            oldDone <= wDone;
                
            rising_edge_done := wDone and (not(oldDone));
            
            if (wDone = '1' and rising_edge_done = '0') then
                done <= '1';
                memOut <= mem_data;
            else
                done <='0';
                memOut <= (others => '0');
            end if;
        end if;
    end process;
       
end Behavioral;

----------------- outSwitcher -----------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity outSwitcher is
    port(
        wParallel : in std_logic_vector(17 downto 0);
        memOut : in std_logic_vector(7 downto 0);
        memDone, clk, rst : in std_logic;
        o_z0, o_z1, o_z2, o_z3 : out std_logic_vector(7 downto 0);
        done: out std_logic
    );
end outSwitcher;

architecture Behavioral of outSwitcher is
signal z0, z1, z2, z3 : std_logic_vector(7 downto 0);
signal oldZ0, oldZ1, oldZ2, oldZ3 : std_logic_vector(7 downto 0);
signal exitNum : std_logic_vector(1 downto 0);
signal oldDone : std_logic;

component register8bit is
    port(in1 : in std_logic_vector(7 downto 0);
        clk, rst : in std_logic;
        out1 : out std_logic_vector(7 downto 0)
    );
end component;
begin
    
    z0_register : register8bit
    port map(in1 => z0, clk => oldDone, rst => rst, out1 => oldZ0);
    z1_register : register8bit
    port map(in1 => z1, clk => oldDone, rst => rst, out1 => oldZ1);
    z2_register : register8bit
    port map(in1 => z2, clk => oldDone, rst => rst, out1 => oldZ2);
    z3_register : register8bit
    port map(in1 => z3, clk => oldDone, rst => rst, out1 => oldZ3);
    
    FIND_EXIT : process(memDone)
    begin
        if memDone = '1' then
            exitNum <= wParallel(17 downto 16);
        else
            exitNum <= (others => '0');
        end if;
    end process;
    
    PROPOSE_EXIT : process(clk, rst)
    variable rising_edge_done : std_logic;

    begin
        if (rst = '1') then
            oldDone <= '0';
            rising_edge_done := '0';
            o_z0 <= (others => '0');
            o_z1 <= (others => '0');
            o_z2 <= (others => '0');
            o_z3 <= (others => '0');
            z0 <= (others => '0');
            z1 <= (others => '0');
            z2 <= (others => '0');
            z3 <= (others => '0');
            done <= '0';
        elsif rising_edge(clk) then
            oldDone <= memDone;
            rising_edge_done := memDone and (not(oldDone));
            
            if rising_edge_done = '1' then
                done <= '1';
                case exitNum is
                    when "00" =>
                        o_z0 <= memOut;
                        o_z1 <= oldZ1;
                        o_z2 <= oldZ2;
                        o_z3 <= oldZ3;
                        z0 <= memOut;
                        z1 <= oldZ1;
                        z2 <= oldZ2;
                        z3 <= oldZ3;
                    when "01" => 
                        o_z0 <= oldZ0;
                        o_z1 <= memOut;
                        o_z2 <= oldZ2;
                        o_z3 <= oldZ3;
                        z0 <= oldZ0;
                        z1 <= memOut;
                        z2 <= oldZ2;
                        z3 <= oldZ3;
                    when "10" =>
                        o_z0 <= oldZ0;
                        o_z1 <= oldZ1;
                        o_z2 <= memOut;
                        o_z3 <= oldZ3;
                        z0 <= oldZ0;
                        z1 <= oldZ1;
                        z2 <= memOut;
                        z3 <= oldZ3;
                    when "11" =>
                        o_z0 <= oldZ0;
                        o_z1 <= oldZ1;
                        o_z2 <= oldZ2;
                        o_z3 <= memOut;
                        z0 <= oldZ0;
                        z1 <= oldZ1;
                        z2 <= oldZ2;
                        z3 <= memOut;
                    when others =>
                        o_z0 <= (others => '0');
                        o_z1 <= (others => '0');
                        o_z2 <= (others => '0');
                        o_z3 <= (others => '0');
                        z0 <= (others => '0');
                        z1 <= (others => '0');
                        z2 <= (others => '0');
                        z3 <= (others => '0');
                end case;
            else
                done <= '0';
                o_z0 <= (others => '0');
                o_z1 <= (others => '0');
                o_z2 <= (others => '0');
                o_z3 <= (others => '0');
                z0 <= (others => '0');
                z1 <= (others => '0');
                z2 <= (others => '0');
                z3 <= (others => '0');
            end if;
        end if;
    end process;
    
end Behavioral;

----------------- register8bit -----------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity register8bit is
    port(in1 : in std_logic_vector(7 downto 0);
        clk, rst : in std_logic;
        out1 : out std_logic_vector(7 downto 0)
    );
end register8bit;

architecture Behavioral of register8bit is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            out1 <= (others => '0');
        elsif clk = '1' and clk'event then
            out1 <= in1;
        end if;
    end process;
end behavioral;
