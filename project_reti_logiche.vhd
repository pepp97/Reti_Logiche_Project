library IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

entity project_reti_logiche is 
	port (
		i_clk : in  std_logic; 
		i_start : in  std_logic; 
		i_rst : in  std_logic; 
		i_data : in  std_logic_vector(7 downto 0);  
		o_address : out std_logic_vector(15 downto 0);
		o_done : out std_logic; 
		o_en  : out std_logic; 
		o_we : out std_logic;
		o_data : out std_logic_vector (7 downto 0)
		); 
	end project_reti_logiche; 
	
	architecture Behavioral of project_reti_logiche is
    --Viene creato un tipo per rappresentare i possibili stati del componente
--	__________________________________-STATI-___________________________________________________________________________________________
	type state_type is (START_WAIT, ACQUISIZIONE_MASCHERA, AUMENTA_INDIRIZZO, WAIT_CLOCK, WAIT_CLOCK_DATA, CALCOLA_DISTANZA, LETTURA_BYTE, ACQUISIZIONE_PUNTO, SCRITTURA_FINALE, DONE_HIGH, DONE_LOW);
	
	

    signal state : state_type; --Questa variabile tiene traccia tra le varie chiamate del processo dello stato in cui si trova il componente
	
--	____________________________________-VARIABILI-______________________________________________________________________________________
	begin
		process(i_clk, i_rst)
	
	variable distanza_m: integer;
	variable x_centroide: integer;
	variable y_centroide: integer;
	variable x_point: integer;
	variable y_point: integer;
	variable indice_centroide: integer; --ci dice quale centroide stiamo analizzando.
	variable tmp_ris: std_logic_vector(7 downto 0); 
	variable curr_add: std_logic_vector (15 downto 0);
	variable maschera_attivazione: std_logic_vector (7 downto 0);
--	___________________________________-MACCHINA A STATI-_________________________________________________________________________________
	begin
        if (i_rst = '1') then --Controllo segnale di reset -Asincrono-
            state <= START_WAIT;
       end if;
        if (rising_edge(i_clk)) then --Sincronizzazione sul fronte di salita del clock
		
            case state is
			
                when START_WAIT => 
                    if (i_start = '1') then
						distanza_m := 513;
						tmp_ris := "00000000"; --maschera messa a 0.
						x_centroide := 0;
						y_centroide := 0;
						x_point := 0;
						y_point := 0;
						maschera_attivazione := "00000000";
						curr_add := "0000000000010001";
						indice_centroide := -1;
						o_address <= curr_add;
						o_en <= '1';
						o_we <= '0';
						state <= WAIT_CLOCK;
					end if;
				
				when ACQUISIZIONE_PUNTO =>
					if(conv_integer(curr_add)=17) then
						x_point:= conv_integer(i_data);
						state <= AUMENTA_INDIRIZZO;
					else
						y_point := conv_integer (i_data);
						curr_add := "0000000000000000";
						state <= WAIT_CLOCK;
				     end if;
				when ACQUISIZIONE_MASCHERA =>
					if(conv_integer(curr_add)=0) then
					o_en <= '1';
                    o_we <= '0';
					maschera_attivazione := i_data;
					state<= AUMENTA_INDIRIZZO;	
					end if;
					
				when AUMENTA_INDIRIZZO =>
					if ((conv_integer(curr_add) < 16) or conv_integer(curr_add) = 17) then
						o_en <= '1';
						o_we <= '0';
						curr_add := curr_add + "0000000000000001";
						o_address <= curr_add;
						state <= WAIT_CLOCK;
					
					elsif (conv_integer(curr_add) =16) then
							state <= SCRITTURA_FINALE;
							
					elsif( conv_integer(curr_add)=18) then
							curr_add :="0000000000000000";
							o_address <= curr_add;
							state <= WAIT_CLOCK;
					
					end if;
				
				when WAIT_CLOCK_DATA =>
				    if(conv_integer(curr_add) = 0) then
				        state <= ACQUISIZIONE_MASCHERA;
				    else
					   state<= LETTURA_BYTE;
					
					end if;
					
				when WAIT_CLOCK =>
				         state <= WAIT_CLOCK_DATA;
				    
				
				when LETTURA_BYTE =>
					if (0 < conv_integer(curr_add) and conv_integer(curr_add)< 17) then
						if (conv_integer(curr_add)=1 or conv_integer(curr_add)=3 or conv_integer(curr_add)=5 or conv_integer(curr_add)=7 or conv_integer(curr_add)=9 or conv_integer(curr_add)=11 or conv_integer(curr_add)=13 or conv_integer(curr_add)=15) then
							x_centroide := conv_integer (i_data);
							indice_centroide := indice_centroide +1;
							state <= AUMENTA_INDIRIZZO;
						else 
							y_centroide := conv_integer (i_data);
							state <= CALCOLA_DISTANZA;
						end if;
						
					else 
						if(conv_integer(curr_add)=17) then
							x_point := conv_integer (i_data);
							state <= AUMENTA_INDIRIZZO;
							
						else 
							y_point :=  conv_integer (i_data);
							state <= AUMENTA_INDIRIZZO;
						
						end if;
					
					end if;
		
				when CALCOLA_DISTANZA =>
					if ((maschera_attivazione(indice_centroide))='1') then
					
						if (distanza_m > (abs(x_centroide - x_point) + abs(y_centroide-y_point)) ) then
							distanza_m := abs(x_centroide - x_point) + abs(y_centroide-y_point);
							if( indice_centroide = 0) then
							     tmp_ris := "00000001";
							     
							elsif( indice_centroide = 1) then
							     tmp_ris := "00000010";
							     
						    elsif( indice_centroide = 2) then
							     tmp_ris := "00000100";
							     
							     
							elsif( indice_centroide = 3) then
							     tmp_ris := "00001000";  
							       
							elsif( indice_centroide = 4) then
							     tmp_ris := "00010000"; 
							     
							elsif( indice_centroide = 5) then
							     tmp_ris := "00100000";
							     
							elsif( indice_centroide = 6) then
							     tmp_ris := "01000000";
							     
							elsif( indice_centroide = 7) then
							     tmp_ris := "10000000";  
							        
							 end if;    
						
						elsif (distanza_m = (abs(x_centroide - x_point) + abs(y_centroide-y_point)))  then
							tmp_ris(indice_centroide):='1';
						
						end if;
					
					end if;
					state<= AUMENTA_INDIRIZZO;
					
					
				when SCRITTURA_FINALE => --Scrittura in memoria del byte più siginificativo
                    o_en <= '1';
                    o_we <= '1';
                    o_address<="0000000000010011"; 
                    o_data <= tmp_ris;
                    state <= DONE_HIGH;
                    
               
               --Stati che alzano il segnale di fine per un ciclo di clock
               when DONE_HIGH =>
                    o_en <= '0';
                    o_done <= '1';
                    state <= DONE_LOW;
                    
               when DONE_LOW =>
                   o_done <= '0';
                   state <= START_WAIT; --Riporta il componente allo stato iniziale pronto per eseguire un'altra operazione
                    
           end case;
        end if;
    end process;
end Behavioral;
					
					
					
					
					
				
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
	