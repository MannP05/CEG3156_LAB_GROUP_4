-- resources used to understand the code:
-- https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Defining-Your-Own-VHDL-Packages
-- https://www.youtube.com/watch?v=PUC2qvSddXA&list=PLitM9dOPMFEdGUXPxIT5YzKmns7kwAmKo 

-- this is probably allowed. This make the code more readable and easier to understand. It also allows us to use the same type in multiple files without having to redefine it each time. We can just import the package and use the type.


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE mux_package IS
    TYPE bus_array_32 IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
END PACKAGE mux_package;


