#!/usr/bin/perl
use List::Util qw(max sum);
use List::UtilsBy qw(max_by);
#use List::MoreUtils qw(first_index uniq);
use Data::Dumper;

#perl gradient_descents.pl bestqs guess_best_byQ 10 0 0.1 freq_pwdset_ovr.txt 2 freq_d0_ovr.txt freq_d0_ovr.txt 0.3 0.7
#perl gradient_descents.pl $reset_q $guess_choice $m_tot $loop $B_fraction $pwdset_dist $num_of_dictionaries $dict1_dist $dict2_dist $actual_q1 $actual_q2


my $reset_q = $ARGV[0];
my $guess_choice = $ARGV[1];
my $m_tot = $ARGV[2];
my $loop = $ARGV[3];
my $B_fraction = $ARGV[4];
my $pwdset = $ARGV[5]; 
my $num_of_dictionaries = $ARGV[6]; 
my $pwdset_name = substr($pwdset, 0, -4);
$files[0]= $pwdset;
#system $^X, $program_name, @array;
#Choices:
#guesses $m
#descents $gradient_loop
#stopping conditions.

#resetting qs:
	#-bestqs
	#-randomqs
	#-averageqs
#choose guess
	#-guess_best_byQ
	#-guess_best_from_best
	#-guess_best_from_rand

#print "loop $loop\n$reset_q, $guess_choice\n";

#read in the names of the dictionaries to the arrays.
for(my $i=1; $i<=$num_of_dictionaries; $i++){
	$files[$i] = $ARGV[$i+6];
	$dicts[$i-1] = $ARGV[$i+6];
	$dicts_temp[$i-1] = $ARGV[$i+6];

}

#actual q values - if not known then it just means the L1s are not meaningful.
#for(my $i=0; $i<$num_of_dictionaries; $i++){
#	$actual_q[$i]= $ARGV[$i+7+$num_of_dictionaries];
#}


#print "files:\n".Dumper(\@files);
#print "dicts:\n".Dumper(\@dicts);
#print "Actual_q:\n".Dumper(\@actual_q);
#$pwdset = $files[0];

#variables for choosing passwords subroutine.
foreach $dict (@dicts){
	$count{$dict} = 0;
}
$flag= 0;
$count2=0; 
$count3=0; 



#Read files into hashes.
my $count = 0;
my $prev = 0;
foreach $file (@files){
	open(FILE, '<', $file) or die "Could not open: $!";
	$D{$file} = 0;
	$count = 0;
	while($line = <FILE>){
		chomp $line;
   		my ($freq, $word) = split " ", $line;
   		${$hashhash{$file}}{$word} = $freq;
		$D{$file} +=$freq;
		if($file eq $pwdset){
			$N_opt[$count] = $freq + $prev; 
			$prev=$N_opt[$count];
		}
		$count++;
	}	

}

for($i=$count+1; $i<$m_tot; $i++){

	$N_opt[$i] = $N_opt[$count+1];
}

#initialize q_best
foreach $dict (@dicts){
	$q_best{$dict} = 1/$num_of_dictionaries;
}


#num users in files. 
$N_tot = $D{$pwdset};

#hardcode D because I have only take the first few values from the file :/
$D{"web_first_hun_thou.txt"} =15252206;
$D{"comp_first_hun_thou.txt"} =1795;
$D{"flirt_first_hun_thou.txt"} =98912;
$D{"hot_first_hun_thou.txt"} =7300;



$stopping_x=10**-5;
$stopping_L =10**-5;
$stopping_sum_Q = 10**-5;


#Make folder for success results:
system("mkdir -p $pwdset_name/Successes/B_frac_$B_fraction/$reset_q/$guess_choice/");
open(Out_Successes, '>', "$pwdset_name/Successes/B_frac_$B_fraction/$reset_q/$guess_choice/loop_$loop.txt") or die "Could not open out_successes.txt: $!";

#Make folder for log file:
system("mkdir -p $pwdset_name/log_file/B_frac_$B_fraction/$reset_q/$guess_choice/");
open(Out_log_file, '>', "$pwdset_name/log_file/B_frac_$B_fraction/$reset_q/$guess_choice/loop_$loop.txt") or die "Could not open out_log_file.txt: $!";
print Out_log_file "guess k\t\t"; 
if($guess_choice eq 'guess_best_byQ'){
	for(my $w = 0; $w<$num_of_dictionaries; $w++){
		print Out_log_file "(q{$dicts[$w]})(frequency k)\t";
	}	
	print Out_log_file "Q_score(k)\n";
}
else{
	for(my $w = 0; $w<$num_of_dictionaries; $w++){
		print Out_log_file "q{$dicts[$w]}\t\t";
	}
	print Out_log_file "Dictionary guess chosen from\n";
}


#Make folder for password guesses:
system("mkdir -p $pwdset_name/Guesses/B_frac_$B_fraction/$reset_q/$guess_choice/");
open(Out_Guesses, '>', "$pwdset_name/Guesses/B_frac_$B_fraction/$reset_q/$guess_choice/loop_$loop.txt") or die "Could not open out_guesses.txt: $!";

#Make folder for l1 norm results (result after gradient descent has finished after each guess):
#system("mkdir -p $pwdset_name/L1/B_frac_$B_fraction/$reset_q/$guess_choice/");
#open(Out_L1, '>', "$pwdset_name/L1/B_frac_$B_fraction/$reset_q/$guess_choice/loop_$loop.txt") or die "Could not open out_L1.txt: $!";

#Make folder for Qvalue results:
system("mkdir -p $pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/");
system("mkdir -p $pwdset_name/QValues/B_frac_$B_fraction/graphs/loop_$loop/");
system("mkdir -p $pwdset_name/QValues/B_frac_$B_fraction/graphs/loop_$loop/all");
open(Out_Q_all, '>', "$pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/all.txt") or die "Could not open out_all_qvalues.txt: $!";
open(Out_Q_all_small_10_100, '>', "$pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/all_10guesses-100descents.txt") or die "Could not open out_all_qvalues.txt: $!";
open(Out_Q_all_small_10_10, '>', "$pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/all_10guesses-10descents.txt") or die "Could not open out_all_qvalues.txt: $!";
open(Out_Q_all_small_100_10, '>', "$pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/all_100guesses-10descents.txt") or die "Could not open out_all_qvalues.txt: $!";
for $fh (*Out_Q_all, *Out_Q_all_small_10_100, *Out_Q_all_small_100_10, *Out_Q_all_small_10_10){
	printf $fh "guess\tdescent\t";
	for(my $i=1; $i<=$num_of_dictionaries; $i++){
		printf $fh "%s\t", $dicts[$i-1];
	}
	printf $fh "\n";
}



#Make folder for likelihood results. 
system("mkdir -p $pwdset_name/Likelihood/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/");
open(Out_Likelihood_m_all, '>', "$pwdset_name/Likelihood/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/all_m.txt") or die "Could not open out_likelihoods.txt: $!";


for(my $m = 0; $m < $m_tot; $m++){
	$gradient_loop=0;

	%q = initialize_qs();
	$k[$m] = make_a_guess(\%q_best);
	printf Out_Guesses "$m\t$k[$m]\n";
	#print "m= $m: $k[$m]\n";
	print Out_log_file "\tN($k[$m]):";
	for(my $w=0; $w<$num_of_dictionaries;$w++){
		printf Out_log_file "\t%d", N($k[$m]); 
	}	
	print Out_log_file "\n";

	# initialize likelihood
	$likelihood_last = Likelihood($m, \%q);
	$best_likelihood = $likelihood_last;
	
	open(Out_Q, '>', "$pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/m=$m.txt") or die "Could not open out_qvalues.txt: $!";
	#include header
	printf Out_Q "descent\t";
	for(my $i=1; $i<=$num_of_dictionaries; $i++){
		printf Out_Q "%s\t", $dicts[$i-1];
	}
	printf Out_Q "\n";
	system("mkdir -p $pwdset_name/QValues/B_frac_$B_fraction/graphs/loop_$loop/m=$m/");
	#open(Out, '>', "".$m."-B=".$B_fraction."Likelihoods".$guess_choice.".txt") or die "Could not open temp.txt: $!";
	open(Out_Likelihood, '>', "$pwdset_name/Likelihood/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/m=$m.txt") or die "Could not open out_likelihood.txt: $!";
	system("mkdir -p $pwdset_name/Likelihood/B_frac_$B_fraction/graphs/loop_$loop/m=$m/likelihood");
	system("mkdir -p $pwdset_name/Likelihood/B_frac_$B_fraction/graphs/loop_$loop/m=$m/best_likelihood");
	system("mkdir -p $pwdset_name/Likelihood/B_frac_$B_fraction/graphs/loop_$loop/m=$m/likelihood_diff");
	system("mkdir -p $pwdset_name/Likelihood/B_frac_$B_fraction/graphs/loop_$loop/likelihood_each_m");
	system("mkdir -p $pwdset_name/Likelihood/B_frac_$B_fraction/graphs/loop_$loop/best_likelihood_each_m");
	system("mkdir -p $pwdset_name/Likelihood/B_frac_$B_fraction/graphs/loop_$loop/likelihood_diff_each_m");
	printf Out_Likelihood_m_all "%d\t%.4f\t%.4f\t%.4f\n", $m, $likelihood, $best_likelihood, $like_diff;

	while($gradient_loop<100){
		printf Out_Q "%d\t", $gradient_loop;
		printf Out_Q_all "%d\t %d\t", $m, $gradient_loop;
		if($m <10 && $gradient_loop<10){
			printf Out_Q_all_small_10_10 "%d\t %d\t", $m, $gradient_loop;
		}
		if($m <10 && $gradient_loop<100){
			printf Out_Q_all_small_10_100 "%d\t %d\t", $m, $gradient_loop;
		}
		if($m <100 && $gradient_loop<10){
			printf Out_Q_all_small_100_10 "%d\t %d\t", $m, $gradient_loop;
		}

		for(my $i=0; $i<$num_of_dictionaries; $i++){
			printf Out_Q "%.4f\t", $q{$dicts[$i]};
			printf Out_Q_all "%.4f\t", $q{$dicts[$i]};
			if($m <10 && $gradient_loop<10){
				printf Out_Q_all_small_10_10 "%.4f\t", $q{$dicts[$i]};
			}
			if($m <10 && $gradient_loop<100){
				printf Out_Q_all_small_10_100 "%.4f\t", $q{$dicts[$i]};
			}
			if($m <100 && $gradient_loop<10){
				printf Out_Q_all_small_100_10 "%.4f\t",$q{$dicts[$i]}; 
			}
		}
		printf Out_Q "\n";
		printf Out_Q_all "\n";
		if($m <10 && $gradient_loop<10){
			printf Out_Q_all_small_10_10 "\n";
		}
		if($m <10 && $gradient_loop<100){
			printf Out_Q_all_small_10_100 "\n";
		}
		if($m <100 && $gradient_loop<10){
			printf Out_Q_all_small_100_10 "\n";
		}
		
		
		$max_old = max %q;
		$gradient = GRADIENT(\@k, $m);

		#normalise gradient
		$norm_grad = Normalise_gradient($gradient);

		#calc beta
		$B = Beta($norm_grad);	

		#update q0 q1 q2. 
		%q = update_qs(\%q, $norm_grad, $B);
		
		#likelihood
		#print "within descent: guess no $m, loop  $gradient_loop\n";
		$likelihood = Likelihood($m, \%q);
		if($likelihood > $best_likelihood){
			%q_best = %q;
			#print "New likelihood is better than old. new > best = $likelihood > $best_likelihood\n";
			$best_likelihood = $likelihood; 
		}
		$like_diff = $likelihood - $likelihood_last;
		#include this for plotting Likelihood as it descends 
		printf Out_Likelihood "%d\t%.4f\t%.4f\t%.4f\n", $gradient_loop, $likelihood, $best_likelihood, $like_diff;

		if(abs($like_diff) < $stopping_L){#stoping condition 2.
			#print "Stopping condition: f(xn)- f(n+1) < $stopping_L @ gradient loop $gradient_loop\n";
			#last;	
		}
		$likelihood_last = $likelihood;

		# changing q stopping condition
		$max_new = max %q;
		if (abs($max_old - $max_new) < $stopping_x){
			#print "Stopping condition reached: ||x_n - x_(n+1)||inf < $stopping_x @ gradient loop $gradient_loop\n";
			#last;
		}
		$gradient_loop++;

	}
	#print "gradient loop finished on $gradient_loop\n";
	#$L1 = 0;
	#for(my $i=0; $i<$num_of_dictionaries; $i++){
	#	$L1 += abs($q_best{$dicts[$i]}-$actual_q[$i]);
		#printf "dict 1: %s, q dicts 1: %f, actual q: %f   \n", $dicts[$i], $q_best{$dicts[$i]}, $actual_q[$i]; 
	#}
	#printf Out_L1 "%d\t %.4f \n", $m+1, $L1;

	#$Linf = max (abs($q_best{"freq_d0_big.txt"}-$actual_q[0]), abs($q_best{"freq_d1_big.txt"}-$actual_q[1]), abs($q_best{"freq_d2_big.txt"}-$actual_q[2]));

	printf Out_Successes "%d\t %d \n", $m+1, $sum_N;
	

	if($sum_N ==$N_tot){print "Guessed all users' passwords. $N_tot == $sum_N\n"; exit();}#stop if we have made all guesses necessary. #print "Guessed all users' passwords. $N_tot ==$sum_N\n"; 


}

sub initialize_qs{

	if($reset_q eq "bestqs"){
		#use the best qs from the last loop.
		%q = bestqs();
	}
	elsif($reset_q eq "randomqs"){
		#randomly choose new q values.
		%q = randomqs();

	}
	elsif($reset_q eq "averageqs"){
		#reset to 1/#num_dicts each time: 
		%q = averageqs();
	}
	return %q;
	
}
sub randomqs{
	foreach $dict (@dicts){
		$r{$dict} = rand(1);
	}
	$sum_r = sum values %r;
	foreach $dict (@dicts){
		$q{$dict} = $r{$dict}/$sum_r; # Normalize so the sum is 1.
		#$q_sum +=$q{$dict};
	}

	return %q;

}
sub bestqs{
	%q = %q_best;
	return %q;

}
sub averageqs{
	foreach $dict (@dicts){
		$q{$dict} = 1/$num_of_dictionaries;
	}
	return %q;
}

sub update_qs{
	my $q = @_[0];
	%q = %$q;
	my $grad = @_[1];
	%grad = %$grad;
	my $B = @_[2];
	foreach $dict (@dicts){
		$q_new{$dict} = $q{$dict} + $B_fraction*$B*$grad{$dict};	
	} 
	return %q_new;
}

sub Beta{
	my $grad = @_[0];
	my %grad = %$grad;
	my $sum_new_gs =0;
	foreach $dict (@dicts){
		$sum_new_gs += abs($grad{$dict});
	}
	if($sum_new_gs != 0){
		$B = 1/$sum_new_gs;
	}
	else{$B=1;}
	if ($B >1){
		$B=1;
	}

	foreach $dict (@dicts){
		while($q{$dict}+$B*$grad{$dict} >1 || $q{$dict}+$B*$grad{$dict} <0){
			$B/=2;
		}
	}
	
	return $B;
	

}

sub Normalise_gradient{
	my $grad = @_[0];
	my %grad = %$grad;
	my $alpha =0;
	foreach $dict (@dicts){
		$alpha +=$grad{$dict};
	}	
	foreach $dict (@dicts){
		$grad{$dict} -= $alpha/$num_of_dictionaries;
	}
	return \%grad;

}




#calc log Likelihood(without multinomial)
sub Likelihood{
	my $m = @_[0];
	my $q = @_[1];
	my %q = %$q;
	for ($j=0;$j<=$m; $j++){
		$temp = Q($k[$j], \%q);
		if ($temp ==0){
			print "temp = $temp =0\n";
			print "dicts temp: ".Dumper(\@dicts_temp);
			exit();
		}
		$NQ[$j] = N($k[$j])*log(Q($k[$j], \%q));
		$Q[$j] = Q($k[$j], \%q);
		$N[$j] = N($k[$j]);
	}
	#Log likelihood
	$sum_NQ= sum @NQ;
	$sum_N = sum @N;
	$sum_Q = sum @Q;
	if (1-$sum_Q<$stopping_sum_Q){
		print "We know the full distribution of the pwdset because we have sampled everything. sum Q == $sum_Q.\n";	#note this ends before the last guess. But it isn't really a gradient descent problem if we have tested every sample. 
		exit();
	}
	$log_sum_Q = log(1-$sum_Q);
	$L = (sum @NQ) + ($N_tot - (sum @N))*log(1- (sum @Q));
	return $L;
}

#Factorial
sub fact{
	my $number = @_[0];
	my $fact = 1;
	for(my $i = 1; $i <= $number ; $i++ ){
    		$fact = $fact*$i;
	}
	return $fact;
}

sub GRADIENT{
	my $k = @_[0];
	my $m = @_[1];
	@k = @$k; 

	for (my $j =0; $j <=$m; $j++){
		# add onto the arrays the additional information for this new guess. 
		$Q[$j] = Q($k[$j], \%q);
		$N[$j] = N($k[$j]);		

		#Calculate the new entries in the proportion array for this new guess. 
		foreach $dict (@dicts){
			${$p{$dict}}[$j]= p($dict, $k[$j]);
			${$part1{$dict}}[$j] = $N[$j]*${$p{$dict}}[$j]/$Q[$j];
		}
	}

	#calc gradient
	foreach $dict (@dicts){
		$sum_N = sum @N; 
		$sum_part1 = sum @{$part1{$dict}};
		$sum_p = sum @{$p{$dict}};
		$sum_Q = sum @Q;
		$gradient{$dict} = ($sum_part1) + ($N_tot - $sum_N)*(-$sum_p)/(1-$sum_Q);
	}

	return \%gradient;
}
sub p{
	my $dict = @_[0];
	my $k = @_[1];
	$value = ${$hashhash{$dict}}{$k}/$D{$dict};
	return $value;

}
sub N{
	my $k = @_[0];
	$Nk = ${$hashhash{$pwdset}}{$k};
	if($Nk){}
	else{
		$Nk =0;	
	}
	return $Nk;
}

sub Q{
	my $k = @_[0]; 
	my $q = @_[1];
	my %q = %$q;
	my $Q = 0;
	foreach $dict (@dicts){
		$value = ${$hashhash{$dict}}{$k}/$D{$dict};
		$prod = $q{$dict}*$value;
		$Q += $q{$dict}*$value;
		#print "$dict\t$k\t$value\t$prod\t$Q\n";
	}
	return $Q;
}





#how would we like to make guesses?
sub make_a_guess{
	my $q_best = @_[0];
	my $k;
	if($guess_choice eq "guess_best_byQ"){
		#OPTION1: most_likely_combining_all_dict
		$k = guess_best_byQ($q_best);
	}
	elsif($guess_choice eq "guess_best_from_best"){
		#OPTION2: most_likely_from_most_likely_dict
		$k = guess_best_from_best($q_best);
	}	
	elsif($guess_choice eq "guess_best_from_rand"){
		#OPTION3: most_likely_word_from_rand_dict
		$k = guess_best_from_rand();
	}	
	return $k;
}

sub guess_best_byQ{
	my $q = @_[0];
	my %q = %$q;
	#calculate Q for every password option. 
	#Choose the password with the highest Q
	#I have a hash of frequencies. 
	#need to calc based on the curret qs.
	my %Q_all;
	foreach $dict (@dicts){#would ned to sort and take top one. 
		foreach $word (keys %{$hashhash{$dict}}) {
			if($guessed{$word} == 1){next;}
			$Q_all{$word} = Q($word, \%q);
		}
	}
	if($count3 == scalar %Q_all){
		print"Nothing left to guess.\n";
		exit();
	}
	my $k =  ((sort {$Q_all{$b} <=> $Q_all{$a}} keys %Q_all)[0]);#changed this
	$guessed{$k}=1;
	$count3 ++;	
	print Out_log_file "$k \t\t";
	for(my $w=0; $w<$num_of_dictionaries;$w++){
		printf Out_log_file "(%.4f)(%.4f)\t\t\t", $q{$dicts[$w]}, $hashhash{$dicts[$w]}{$k}; 
	}
	print Out_log_file "$Q_all{$k}\n";
	return $k;
	
}



sub guess_best_from_best{
	if($count2 == $num_of_dictionaries){
		print "All dictionaries empty.\n"; 
		exit();
	}
	my $q = @_[0];
	my %q = %$q;
	my $k;
	my $i=0;
	my $count2 =0;
	my $l =0;
	do{
		#Choose the best dictionary which is not empty
		$best_dict = ((sort {$q{$b} <=> $q{$a}} (keys %q))[$count2]);#find key corresponding to largest q value. 
		for($w=0; $w<$num_of_dictionaries;$w++){
			if($dicts[$w] eq "$best_dict"){
				$index = $w;
				last;
			}
		}
		if($count{$best_dict} == scalar %{$hashhash{$best_dict}}) {
			$count2++;
			if($count2== $num_of_dictionaries){print "All dictionaries empty.\n"; exit();}
		}
		$l++;
	}while($count{$best_dict} == scalar %{$hashhash{$best_dict}} && $l<=10);

	do{
		while($count{$best_dict}== scalar %{$hashhash{$best_dict}}){
			#print"Nothing left in dictionary $best_dict.\n";
			$count2 ++;
			$best_dict = ((sort {$q{$b} <=> $q{$a}} (keys %q))[$count2]);
			if($count2 == $num_of_dictionaries && $guessed{$k} == 1){print "All dictionaries empty.\n"; exit();}
		}
		$k =  ((sort {${$hashhash{$best_dict}}{$b} <=> ${$hashhash{$best_dict}}{$a}} (keys(%{$hashhash{$best_dict}})))[$count{$best_dict}]);#choose the next largest value from the chosen dict.
		$count{$best_dict}++;#array keeps track of how many times we chose each dict.
		$i++;
	}while($guessed{$k} == 1 && $i<=10);
	$guessed{$k} =1;
	$count{$best} ++;
	print Out_log_file "$k\t\t";
	for(my $w=0; $w<$num_of_dictionaries;$w++){
		printf Out_log_file "%.4f\t\t\t", $q{$dicts[$w]}; 
	}
	print Out_log_file "$best_dict\n";
	return $k;
}

sub guess_best_from_rand{
	#randomly choose a dictionary to choose from: 
	my $k;
	if($flag == $num_of_dictionaries){print "All dictionaries empty.\n"; exit();}
	my $chose = $dicts_temp[rand @dicts_temp];
	do{
		$k =  ((sort {${$hashhash{$chose}}{$b} <=> ${$hashhash{$chose}}{$a}} (keys(%{$hashhash{$chose}})))[$count{$chose}]);
		$count{$chose}++;#array keeps track of how many times we chose each dict.
		if($count{$chose}== scalar %{$hashhash{$chose}}){
			for($w=0; $w<$num_of_dictionaries;$w++){
				if($dicts[$w] eq "$best_dict"){
					$index = $w;
					last;
				}
			}
			splice (@dicts_temp, $index, 1);
			$chose = $dicts_temp[rand @dicts_temp];
			$flag ++; 
			if($flag == $num_of_dictionaries && $guessed{$k} == 1){print "All dictionaries empty.\n"; exit();}
		} 
	}while($guessed{$k} == 1);	
	$guessed{$k} =1;
	print Out_log_file "$k\t\t";
	for(my $w=0; $w<$num_of_dictionaries;$w++){
		printf Out_log_file "%.4f\t\t\t", $q{$dicts[$w]}; 
	}
	print Out_log_file "$chose\n";	
	return $k;
}

sub read_file_to_hash{
	my $file = @_[0];
	open(FILE, '<', $file) or die "Could not open: $!";
	$D=0;
	while($line = <FILE>){
		chomp $line;
   		my ($freq, $word) = split " ", $line;
   		${$lists{$file}}{$word} = $freq;
		$D +=$freq;
	}
	return (\%list, $D);
}


