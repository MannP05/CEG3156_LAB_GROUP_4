-- resources used to understand the code:
-- https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Defining-Your-Own-VHDL-Packages
-- https://www.youtube.com/watch?v=PUC2qvSddXA&list=PLitM9dOPMFEdGUXPxIT5YzKmns7kwAmKo 

-- this is probably allowed. 
--------------------------------------------------------------------------------
-- Title         : Mux Package
-- Project       : Lab2
-------------------------------------------------------------------------------
-- File          : mux_package.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : A VHDL package defining custom data types for the project. 
--               It declares 'bus_array_8', an array of eight 8-bit standard 
--               logic vectors. This custom type improves code readability 
--               and allows for clean type reuse across multiple files.
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE mux_package IS
    TYPE bus_array_8 IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
END mux_package;


