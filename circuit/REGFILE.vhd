library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity register_file is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        we    : in  std_logic;                      -- Write Enable
        wa    : in  std_logic_vector(4 downto 0);   -- Write Address (rd / rt)
        wd    : in  std_logic_vector(31 downto 0);  -- Write Data
        ra1   : in  std_logic_vector(4 downto 0);   -- Read Address 1 (rs)
        ra2   : in  std_logic_vector(4 downto 0);   -- Read Address 2 (rt)
        rd1   : out std_logic_vector(31 downto 0);  -- Read Data 1
        rd2   : out std_logic_vector(31 downto 0)   -- Read Data 2
    );
end entity register_file;

architecture rtl of register_file is
    -- Definición del banco de 32 registros de 32 bits
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal regs : reg_array;
begin

    -- Puerto de lectura 1 (Combinacional / Asíncrono)
    -- Si la dirección es 0 ($zero), retorna siempre 0.
    process(ra1, regs)
    begin
        if to_integer(unsigned(ra1)) = 0 then
            rd1 <= (others => '0');
        else
            rd1 <= regs(to_integer(unsigned(ra1)));
        end if;
    end process;

    -- Puerto de lectura 2 (Combinacional / Asíncrono)
    -- Si la dirección es 0 ($zero), retorna siempre 0.
    process(ra2, regs)
    begin
        if to_integer(unsigned(ra2)) = 0 then
            rd2 <= (others => '0');
        else
            rd2 <= regs(to_integer(unsigned(ra2)));
        end if;
    end process;

    -- Puerto de escritura (Síncrono al flanco de subida del reloj)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Inicialización por reset según especificación [R6]
                for i in 0 to 31 loop
                    regs(i) <= (others => '0');
                end loop;
                regs(28) <= x"00001800"; -- $gp inicial = 0x1800[span_5](start_span)[span_5](end_span)[span_6](start_span)[span_6](end_span)
                regs(29) <= x"00003FFC"; -- $sp inicial = 0x3FFC[span_7](start_span)[span_7](end_span)[span_8](start_span)[span_8](end_span)
            else
                -- Escritura condicional (el registro $zero / $0 nunca se modifica)
                if we = '1' and to_integer(unsigned(wa)) /= 0 then
                    regs(to_integer(unsigned(wa))) <= wd;
                end if;
                -- Garantizar por seguridad que $zero permanezca en 0
                regs(0) <= (others => '0');
            end if;
        end if;
    end process;
end architecture rtl;