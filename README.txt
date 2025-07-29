
################################################################################################
BARD (Bayesian Approach to Resonator Design)
Written by Atkin Hyatt (atkindavidhyatt@arizona.edu or atkindh@gmail.com)
Quantum Optomechanics Laboratory, University of Arizona Wyant College of Optical Sciences
################################################################################################

# Requirements:
   - MATAB 2020b or later
   - Statistics and Machine Learning Toolbox add-on for MATLAB
   - COMSOL 5.4 or later
   - COMSOL LiveLink w/ MATLAB (available on the COMSOL install wizard)


# Introduction:

  	When designing nanomechanical resonators, we need to take many different factors into
  consideration. The frequency, quality factor, shape, and effective mass of an oscillator's
  mode can be specially tailored for many different applications, each of which has its own
  unique list of additional challenges. Intuition typically gets a qualitative idea of what
  a device should or should not look like but it's often difficult or expensive to nail down
  quantitative design parameters. This package aims to solve this problem by combining the
  computational power of COMSOL with the versatility of MATLAB and its Bayesian optimization
  algorithm.
	The package works by opening a specified COMSOL file using a LiveLink server and passing 
  calculations to and from MATLAB's optimizer, called 'bayesopt'. The optimizer iteratively
  determines design parameters and evaluates their performance in a user-specified objective
  function. This is where MATLAB sends the parameters to COMSOL and COMSOL spits out an
  evaluation group result. The optimizer then uses this information to determine new parameters
  and the cycle continues until it has iterated a specified amount.

  - This software was specifically designed for use in designing ultrahigh Q torsion ribbon
    resonators, more details can be found here: https://doi.org/10.48550/arXiv.2506.02325



# The 'ResOpt' Object:

  The operation of 'bayesopt' is inherently reliant on functions so, for ease of use, all
  variables relevant to the optimization script are stored in a 'ResOpt' object. These variables
  are as follows:

  * File and Session Names
    - 'name' -> Session name, also the name that shows up on saved files and figures.
    - 'pathname' -> File path of COMSOL file (mostly obsolete).
    - 'filename' -> COMSOL file name.
    - 'figNum' -> Figure index of optimization plotting figure, default 1.

  * Basic Settings
    - 'maxit' -> Number of iterations the algorithm will make in optimizing the objective
    - 'initialNum' -> The algorithm needs to sample the objective function randomly before it
                      can start estimating optimal parameters, this variable tells it how many
                      initial iterations should be dedicated to this.
    - 'expRatio' -> Exploration ratio, controls how much the algorithm explores/exploits a
                    region of parameter space.
    
  * Optimization Settings
    - 'funcs' -> Function handle that the optimizer will call between iterations, useful for
		 tracking its progress or extracting additional data. A function that does this
		 already exists and is called 'trackOptimization.m'.
    - 'objectiveFunction' -> Function handle of the objective function used to evaluate the
                             performance of a set of parameters. This interfaces with COMSOL and
			     requires special commands, see section 'Designing an Objective
			     Function'
    - 'acqfunc' -> String specifying which built-in acquisition function will be used in the
		   optimization process, see the powerpoint for more information. By default,
		   this is set to expected improvement plus.
    - 'constraints' -> Function handle of logical constraints on optimizable parameter values

  * Optimizable Variables
    - 'varNames' -> 1D vector of strings denoting the names of the parameters which are to be
		    optimized as defined in the user's COMSOL file.
    - 'lims' -> Nx2 matrix specifying the range of values over which optimizable variables can 			take. Takes the form [x1_lower, x1_upper; x2_lower, x2_upper; ...].
    - 'vars' -> 1D vector of optimizable variables initialized specially for the optimizer.

  * Static Parameters
    - 'staticParams' -> Mx2 cell array specifying a parameter that should be controlled but not
                        optimized (fixed resonator length for example). Note that it's not 				necessary to define every parameter in the COMSOL file this way, only 				the ones which are to be changed in say a sweep. Takes the form
			{'Param1',paramVal; 'Param2',paramVal2; ...}.
    - 'intermediateData' -> 2D matrix for extracting extra data from the objective function. 				    Since this is dependent on the objective function, the user can
			    store data by any means they see fit.

  * Dependents
    - 'numOpt' -> Number of optimizable variables
    - 'numStat' -> Number of static variables

  * Methods
    - 'ResOpt(varargin)' -> Must be called to initialize the 'ResOpt' object. Arguments passed
			    to allow the user to set the session and COMSOL file names faster.
			    If no file name is specified, a file browser interface will pop up
			    and allow the user to search for it manually.
    - 'generateVars(P)' -> Must be called to start the optimization. This function converts the 		           optimizable variables from the user to the 'optimizableVariable' 				   class for 'bayesopt'.


# The 'globalParameters()' Function and Passing a 'ResOpt' Object Between Functions:

  	MATLAB's 'bayesopt' function is really nice but was designed for training large neural
  networks, not COMSOL simulations. It does not care about static parameters or filenames so the
  objective function is only allowed to take optimizable variables for inputs. Since MATLAB does
  not like explicitly defining global variables, we take another approach: saving the entire
  'ResOpt' object as a persistent class type in a function. This is what the function
  'globalParameters()' is for. When there are a nonzero number of arguments in (such as
  'globalParameters(P)'), the function saves that variable (or object). When called with no
  arguments, 'globalParameters()' returns the saved variable regardless of which function it was
  called in.


# Designing an Objective Function:

 * The objective function is the optimizer's method of evaluating the "goodness" of a design.
   Usually this would be the resonator quality factor or Qm/f for a specific mode but in general
   could be anything, keep the following in mind:
    - It's usually easier to compute the performance evaluation (Q or Qm/f) in COMSOL and
      extract it using MATLAB
    - Though 'bayesopt' is only able to minimize an objective function, it can be tricked into
      maximizing it by multiplying the objective function by -1.
    - There are no limits as to what the objective function can quantify but the optimizer does
      make assumptions on its smoothness. The details of the fitting process are complicated and
      will be updated in later releases.
    - The objective function must only take one table variable for input. Individual parameter
      values can be accessed either by dot-indexing or by converting to a vector. Converting to
      a 1D vector is recommended since dot indexing is harder to automate.
    - The values 'bayesopt' sends to the objective function are in table-format listed in the
      order that they were listed in in the 'varNames' property of the ResOpt object.

 * LiveLink is a very powerful program that allows a user to manipulate any aspect of a COMSOL
   file directly from MATLAB. The user's manual talks about this is great detail but here are a
   few useful LiveLink commands in the context of this package:
    - 'model.param.set(<name>,val)' -> Changes parameter <name>'s value to val.
    - 'model.sol(<soltag>).run' -> Runs the COMSOL solution <soltag>. Leave this blank if
                                   there's just one solution node.
    - 'model.result.numerical(<evaltag>).getReal' -> Runs and collects data from the evaluation
						     node with the tag <evaltag>.
    - 'mphglobal(model,var)' -> Evaluates the global variable var in model.
    - 'model.result.param.set(<name>,val)' -> Same as 'model.param.set' but affects parameters
					      in the Result group (not the same as global
					      parameters). Required for changing evaluation
					      group parameters after running a simulation.


# Constraining the optimizable variables:

  	The optimizable variables, by default, need to have a specified range over which they
  can take on values. But sometimes certain combinations of theses parameters may lead to
  nonphysical designs and COMSOL will spit out an error. In these cases, the parameters need to
  be constrained further and in relation to any other parameters (static or optimizable).
  	The way 'bayesopt' handles this is by generating 10,000 different parameter
  configurations and testing each one in a user-specified function before the optimization
  begins. This function accepts a 10,000xN table as an input with each column representing one
  optimizable variable and each row a different configuration. The constraints themselves are
  logic expressions, one for each constraint needed. At the end of the function, calculate
  constr1 & constr2 & ..., this will be the value returned by the constraint function.


# For more information, see the references folder as well as the MATLAB bayesopt help page:
  https://www.mathworks.com/help/stats/bayesopt.html
