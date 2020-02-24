	component probe_16b is
		port (
			source : out std_logic_vector(15 downto 0);                    -- source
			probe  : in  std_logic_vector(15 downto 0) := (others => 'X')  -- probe
		);
	end component probe_16b;

	u0 : component probe_16b
		port map (
			source => CONNECTED_TO_source, -- sources.source
			probe  => CONNECTED_TO_probe   --  probes.probe
		);

