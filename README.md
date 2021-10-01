# multi-armed-bandit-guessing

This repositary contains supplementary material for our work on the multi-armed bandit approach to guessing.

In MAB_variable_choice.pdf, we discuss each variable type and investigate which value each variable should take in order for the multi-armed bandit model to produce the best results.

In Proof_of_Theorem1__Concavity_of_the_Log_Likelihood_function.pdf, we provide the proof of Concavity. 

In the code directory, we provide the code for implementing the multi-armed bandit. The gradient descent perl files contain the code for the gradient descent computaiton of the maximum likelihood. It begins with starting q estimates where each q_i represents a wordlist. It then makes a guess, gathers information based on the success of this guess and compares this to each one of the wordlists. We then use gradient descent to get new q estimates based on this new information.

The looping programs in the code directory, runs the full gradient descent for different iterations of the Multi-armed bandit set-up. It will generate results for the three different q-value initialisation methods and the three different methods of guessing. It allows us to run lots of different set ups from the same place to make comparisons. 

It links to gnuplot code which are just simple files for plotting the results. 
