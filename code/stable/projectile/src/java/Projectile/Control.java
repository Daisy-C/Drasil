package Projectile;

/** \file Control.java
    \author Samuel J. Crawford, Brooks MacLachlan, and W. Spencer Smith
    \brief Controls the flow of the program
*/
public class Control {
    
    /** \brief Controls the flow of the program
        \param args List of command-line arguments
    */
    public static void main(String[] args) throws Exception {
        String filename = args[0];
        InputParameters inParams = new InputParameters(filename);
        double g_vect = 9.8;
        double epsilon = 2.0e-2;
        double t_flight = Calculations.func_t_flight(inParams, g_vect);
        double p_land = Calculations.func_p_land(inParams, g_vect);
        double d_offset = Calculations.func_d_offset(inParams, p_land);
        String s = Calculations.func_s(inParams, epsilon, d_offset);
        OutputFormat.write_output(s, d_offset);
    }
}
