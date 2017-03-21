% This is an expert-system shell, written in Prolog.
% ------------------------------------------------
% author Miki Maine
% email mikias.amdu@gmail.com
% website www.tmgproduction.com 
% ------------------------------------------------
% The diagnosis is initiated by the goal 'solve'.
% ------------------------------------------------
:- write('Plese plese').
solve :- solve(fix(X),CF), nl.
solve :- retractall(know(_,_)), 
        write('There is insufficient knowledge to make a diagnosis'), 
        nl.
% The notation "solve/2" means "solve with 2 arguments". 
% solve/2 succeeds with 
% argument 1 bound to a goal proven true using the current knowledge base 
% argument 2 bound to the confidence in that goal. 
% 
% solve/2 calls solve/4 with appropriate arguments.  After solve/4 has completed,  
% it writes the conclusions and prints a trace. 
solve(Goal, CF) :- retractall(known(_,_)),
 solve(Goal, CF, [], 20),  % use 20 as the threshold for pruning rules 
 write(Goal), write(' was concluded with certainty '), write(CF), nl,nl,
 write('Do you want to see the proof and trace? ( y or halt)'),read(T),(T==y)->build_proof(Goal, _, Proof),nl, 
           write('The proof is '),nl,nl, 
           write_proof(Proof, 0), nl,nl ; !.

%solve/4 succeeds with 
% argument 1 bound to a goal proven true using the current knowledge base 
% argument 2 bound to the confidence in that goal. 
% argument 3 bound to the current rule stack 
% argument 4 bound to the threshold for pruning rules. 
% 
%solve/4 is the heart of exshell.  In this version, I have gone back to the 
% simpler version.  It still has problems with negation, but I think that 
% this is more a result of problems with the semantics of Stanford Certainty 
% factors than a bug in the program. 
% The pruning threshold will vary between 20 and -20, depending whether, 
% we are trying to prove the current goal true or false. 
% solve/4 handles conjunctive predicates, rules, user queries and negation. 
% If a predicate cannot be solved using rules, it will call it as a PROLOG predicate.
% Case 1: truth value of goal is already known 
solve(Goal, CF, _, Threshold) :-  
 known(Goal, CF),!, 
 above_threshold(CF, Threshold).
% Case 2: negated goal 
solve( not(Goal), CF, Rules, Threshold) :- !, 
 invert_threshold(Threshold, New_threshold), 
 solve(Goal, CF_goal, Rules, New_threshold), 
 negate_cf(CF_goal, CF).
% Case 3: conjunctive goals 
solve((Goal_1,Goal_2), CF, Rules, Threshold) :- !, 
 solve(Goal_1, CF_1, Rules, Threshold),  
 above_threshold(CF_1, Threshold), 
 solve(Goal_2, CF_2, Rules, Threshold),  
 above_threshold(CF_2, Threshold), 
 and_cf(CF_1, CF_2, CF).
%Case 4: backchain on a rule in knowledge base  
solve(Goal, CF, Rules, Threshold) :- 
 rule((Goal :- (Premise)), CF_rule),  
 solve(Premise, CF_premise,  
  [rule((Goal :- Premise), CF_rule)|Rules], Threshold), 
 rule_cf(CF_rule, CF_premise, CF), 
 above_threshold(CF, Threshold).
%Case 5: fact assertion in knowledge base 
solve(Goal, CF, _, Threshold) :- 
 rule(Goal, CF),  
 above_threshold(CF, Threshold).
% Case 6: ask user 
solve(Goal, CF, Rules, Threshold) :- 
 askable(Goal), 
 askuser(Goal, CF, Rules),!, 
 assert(known(Goal, CF)), 
 above_threshold(CF, Threshold).
% Case 7A: All else fails, see if goal can be solved in prolog. 
% solve(Goal, 100, _, _) :-
% call(Goal).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Certainty factor predicates.  Currently, these implement a variation of  
% the MYCIN certainty factor algebra. 
% The certainty algebra may be changed by modifying these predicates.
% negate_cf/2 
% argument 1 is a certainty factor 
% argument 2 is the negation of that certainty factor 
negate_cf(CF, Negated_CF) :- 
 Negated_CF is -1 * CF.
% and_cf/3 
% arguments 1 & 2 are certainty factors of conjoined predicates 
% argument 3 is the certainty factor of the conjunction 
and_cf(A, B, A) :- A =< B. 
and_cf(A, B, B) :- B < A.
%rule_cf/3 
% argument 1 is the confidence factor given with a rule 
% argument 2 is the confidence inferred for the premise 
% argument 3 is the confidence inferred for the conclusion 
rule_cf(CF_rule, CF_premise, CF) :-  
 CF is CF_rule * CF_premise/100.
%above_threshold/2 
% argument 1 is a certainty factor 
% argument 2 is a threshold for pruning 
% 
% If the threshold, T, is positive, assume we are trying to prove the goal 
% true.  Succeed if CF >= T. 
% If T is negative, assume we are trying to prove the goal 
% false.  Succeed if CF <= T. 
above_threshold(CF, T) :- 
 T >= 0, CF >= T. 
above_threshold(CF, T) :- 
 T < 0, CF =< T.
%invert_threshold/2 
% argument 1 is a threshold 
%  argument 2 is that threshold inverted to account for a negated goal. 
% 
% If we are trying to prove not(p), then we want to prove p false. 
% Consequently, we should prune proofs of p if they cannot prove it 
% false.  This is the role of threshold inversion. 
invert_threshold(Threshold, New_threshold) :-  
 New_threshold is -1 * Threshold.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Predicates to handle user interactions.  As is typical, these  
% constitute the greatest bulk of the program. 
% 
% askuser/3 
% argument 1 is a goal whose truth is to be asked of the user. 
% argument 2 is the confidence the user has in that goal 
% argument 3 is the current rule stack (used for why queries). 
%  
% askuser prints the query, followed by a set of instructions. 
% it reads the response and calls respond/4 to handle that response
askuser(Goal, CF, Rules) :- 
 nl,write('Is it true that there is :  '), write(Goal), nl, 
 write('? '), 
 read(Answer), 
 respond(Answer,Goal, CF, Rules).
% respond/4 
% argument 1 is the user response 
%  argument 2 is the goal presented to the user 
% argument 3 is the CF obtained for that goal 
% argument 4 is the current rule stack (used for why queries). 
% 
% The basic scheme of respond/4 is to examine the response and return 
% the certainty for the goal if possible. 
% If the response is a why query, how query, etc., it processes the query 
% and then calls askuser to re prompt the user.
% Case 1: user enters a valid confidence factor. 
respond(CF, _, CF, _) :- 
 number(CF), 
 CF =< 100, CF >= -100.
% Case 2: user enters 'n' for no.  Return a confidence factor of -1.0  
respond(n, _, -100, _).
% Case 3: user enters 'y' for yes.  Return a confidence factor of 1.0  
respond(y, _, 100, _).
% Case 4: user enters a pattern that matches the goal.  This is useful if 
% the goal has variables that need to be bound.   
respond(Goal, Goal, CF, _) :- 
 write('Enter confidence in answer'), nl, 
 write('?'), 
 read(CF).
% Case 5: user enters a why query 
respond(why, Goal, CF, [Rule|Rules]) :- 
 write_rule(Rule), 
 askuser(Goal, CF, Rules).
respond(why, Goal, CF, []) :- 
 write('Back to top of rule stack.'), 
 askuser(Goal, CF, []).
% Case 6: User enters a how query.  Build and print a proof 
respond(how(X), Goal, CF, Rules) :- 
 build_proof(X, CF_X, Proof),!, 
 write(X), write(' was concluded with certainty '), write(CF_X), nl,nl, 
 write('The proof is '),nl,nl, 
 write_proof(Proof, 0), nl,nl, 
 askuser(Goal, CF, Rules).
% User enters how query, could not build proof 
respond(how(X), Goal, CF, Rules):- 
 write('The truth of '), write(X), nl, 
 write('is not yet known.'), nl, 
 askuser(Goal, CF, Rules).
% Case 7: User asks for the rules that conclude a certain predicate  
respond(rule(X), _, _, _) :- 
 write('The following rules conclude about '), write(X),nl,nl, 
 rule((X :- Premise), CF), 
 write(rule((X :- Premise), CF)), nl, 
 fail.
respond(rule(_),Goal, CF, Rules) :- 
 askuser(Goal, CF, Rules).
% Case 8: User asks for help. 
respond(help, Goal, CF, Rules) :- 
 print_instructions, 
 askuser(Goal, CF, Rules).
%Case 9: User wants to stop running the program. 
respond(halt,_, _, _) :- write(' Thanks for using the diagnosis system.'), 
         nl, nl, abort.
%Case 10: Unrecognized input 
respond(_, Goal,CF, Rules) :- 
 write('Unrecognized response.'),nl, 
 askuser(Goal, CF, Rules).
%build_proof/3 
% argument 1 is the goal being traced. 
% argument 2 is the CF of that goal 
% argument 3 is the proof tree 
% 
% build_proof does not do threshold pruning, so it can show 
% the proof for even goals that would not succeed. 
build_proof(Goal, CF, ((Goal,CF) :- given)) :-  
 known(Goal, CF),!.
build_proof(not(Goal), CF, not(Proof)) :- !, 
 build_proof(Goal, CF_goal, Proof), 
 negate_cf(CF_goal, CF).
build_proof((Goal_1, Goal_2), CF, (Proof_1, Proof_2)) :- !, 
 build_proof(Goal_1, CF_1, Proof_1), 
 build_proof(Goal_2, CF_2, Proof_2), 
 and_cf(CF_1, CF_2, CF).
build_proof(Goal, CF, ((Goal,CF) :- Proof)) :- 
 rule((Goal :- (Premise)), CF_rule), 
 build_proof(Premise, CF_premise, Proof), 
 rule_cf(CF_rule, CF_premise, CF).
build_proof(Goal, CF, ((Goal, CF):- fact)) :- 
 rule(Goal, CF).
% build_proof(Goal, 1, ((Goal, 1):- call)) :- 
% call(Goal).
% write_proof/2 
% argument 1 is a portion of a proof tree 
% argument 2 is the depth of that portion (for indentation) 
% 
% writes out a proof tree in a readable format 
write_proof(((Goal,CF) :- given), Level) :- 
 indent(Level), 
 write(Goal), write(' CF= '), write(CF),  
 write(' was given by the user'), nl,!.
write_proof(((Goal, CF):- fact), Level) :- 
 indent(Level), 
 write(Goal), write(' CF= '), write(CF),  
 write(' was a fact in the knowledge base'), nl,!.
write_proof(((Goal, CF):- call), Level) :- 
 indent(Level), 
 write(Goal), write(' CF= '), write(CF),  
 write(' was proven by a call to prolog'), nl,!.
write_proof(((Goal,CF) :- Proof), Level) :- 
 indent(Level), 
 write(Goal), write(' CF= '), write(CF), write(' :-'), nl, 
 New_level is Level + 1, 
 write_proof(Proof, New_level),!.
write_proof(not(Proof), Level) :- 
 indent(Level), 
 write('not'),nl, 
 New_level is Level + 1, 
 write_proof(Proof, New_level),!.
write_proof((Proof_1, Proof_2), Level) :- 
 write_proof(Proof_1, Level), 
 write_proof(Proof_2, Level),!.
% indent/1 
% argument 1 is the number of units to indent 
indent(0). 
indent(I) :- 
 write('     '), 
 I_new is I - 1, 
 indent(I_new).
%print_instructions/0 
% Prints all options for user responses 
print_instructions :- 
 nl, 
 write('|****************************************************************************************************|'),nl,
 write('|********  WELCOME TO SIMPlLE DISEASE DIAGONISES EXPERT SYSTEM***********|'),nl,
write('|****************************************************************************************************|'),nl,
 write('|    Disease included in this system are:'),nl,
 write('|                                  - Maleria የወባ በሽታ'),nl,
 write('|                                  - Ebola የኢቦላ በሽታ                              '),nl,
 write('|                                  - Diabetes የስኴር በሽታ                            '),nl,
 write('|                                  - Coronary Heart Disease የልብ በሽታ             '),nl,
write('|****************************************************************************************************|'),nl,
 write('|    Please Enter "solve." to start the Diagonises System               '), nl, 
write('|****************************************************************************************************|'),nl,
 write('|    Please answer my questions with one of the following:              '), nl, 
 write('|    "y.", which means "yes" (confidence value 100).                    '), nl, 
 write('|    "n.", which means "no"  (confidence value -100).                   '), nl,  
 write('|    A number followed by a period.  The number, which should be        '), nl, 
 write('|    between -100 and 100, is your confidence in the truth of the query.'), nl, 
 write('|    "why." to get an explanation of why I ask this question.           '),nl, 
 write('|    "how(X)." to find out how confident I am in concluding X,          '),nl, 
 write('|             and how I reached that conclusion.                        '),nl, 
 write('|    "rule(X)." to display all rules that conclude about X.             '),nl, 
 write('|    "halt." to terminate consultation.                                 '),nl, 
 write('|    "help." to print this message.                                     '),nl,
write('|****************************************************************************************************|'), nl,
write('|  By GROUP ONE COMPUTER SCIENCE STUDENTS | WOLKITE UNIVERSITY 2016 |'), nl,
write('|  Group members                                                    |'), nl,
write('|                 1 Mikiyas Amdu                                    |'), nl,
write('|                 2 Mehret abe                                      |'), nl,
write('|                 3 Loza Tsegaye                                    |'), nl,
write('|                 4 Meti                                            |'), nl,
write('|                 5 Fiyori Alem                                     |'), nl,
write('|                 6 wonshet                                         |'), nl,
write('|****************************************************************************************************|'),nl,nl.
% write_rule/1 
% argument 1 is a rule specification 
% writes out the rule in a readable format 
write_rule(rule((Goal :- (Premise)), CF)) :- 
 write(Goal), write('if'), nl, 
 write_premise(Premise),nl, 
 write('CF = '), write(CF), nl.
write_rule(rule(Goal, CF)) :- 
 write(Goal),nl, 
 write('CF = '), write(CF), nl.
% write_premise 
% argument 1 is a rule premise 
% writes it in a readable format. 
write_premise((Premise_1, Premise_2)) :- 
 !, write_premise(Premise_1), 
 write_premise(Premise_2). 
write_premise(not(Premise)) :- 
 !, write('     '), write(not),write(' '), write(Premise),nl. 
write_premise(Premise) :- 
 write('     '), write(Premise),nl.
% Utility Predicates. 
retractall(X) :- retract(X), fail. 
retractall(X) :- retract((X:-Y)), fail. 
retractall(X).