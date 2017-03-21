% This is the sample disease diagnostic knowledge base  
% When running it, be sure to load it with the file containing  
% SysEngine.
% ------------------------------------------------------
% author Miki Maine
% email mikias.amdu@gmail.com
% website www.tmgproduction.com 
% ------------------------------------------------------
% To start it, give PROLOG the goal: solve.
% Knowledge Base for simple diagnostic expert system. 
% Top level goal, starts search.
% ------------------------------------------------------

:- ensure_loaded('SysEngine.pl').
:- print_instructions.
rule((fix(Advice) :- 
 (symptoms_for(X),fix(X, Advice))), 100).
% rules to infer symptoms of the Disease:
rule((symptoms_for(maleria) :-  
 (disease(common_symptom),disease(malaria_related),vomiting(come_on))),90).
 
rule((symptoms_for(ebola) :-  
 (disease(common_symptom),disease(unusual_cases),stomach_pain)),90).
 
 rule((symptoms_for(diabetes) :-  
 (disease(diabetes_related),stomach_pain,frequent_infections,blurred_vision)),90).
 
rule((symptoms_for(coronary_heart_disease) :-  
 (disease(very_dangerse_case), pressure_in_the_chest_at_the_time_of_increased_activity)),90).


% Rules to infer the condition of the person

rule((disease(common_symptom)) :-  
 (headache(high),hight_fever),80).
 
rule((disease(malaria_related)) :-  
 (profuse_sweeting,musle_pain,shaking_chills_that_can_range_from_moderate_to_severe),90).
 
rule((disease(unusual_cases)) :-  
 (bleeding_inside_the_body_as_well_as_eyes_ears_nose,sore_throat),90).
 
 rule((disease(diabetes_related)) :-  
 (frequent_urination,unplanned_weight_loss,increased_hunger,slow_healing_wounds),90).
 
rule((disease(very_dangerse_case) :-  
 (chest_pain(angina),heart_attack,rhythm_disturbances(arrhythmia))),90).
 

% Rules to make reccommendation for cure.

rule(fix(maleria,'
                  |************************************************************************************************
                  | Your Syptoms define Malaria                                                                    
                  |************************************************************************************************
		          | - Your Doctor will be able to diagnose malaria.                                                
                  | - Your doctor will review you health history,includeing any recent travle into tropical climate
                  | - Treatment for the diseaseis typically provided in the hospital                               
                  *************************************************************************************************'),100). 
				   
rule(fix(ebola,'
                  |************************************************************************************************
                  | Your Syptoms define Ebola                                                                      
                  |************************************************************************************************
		          | - Sometimes its hard to tell if a person have Ebola from the syptoms alone.                    
                  | - Test of boold and tissues also can diagnose Ebola.                                           
                  | - If you have Ebola , You will be isolated from the public  immediately to prevent the spread. 
                  *************************************************************************************************'),100). 
				 
rule(fix(diabetes, '
                  |************************************************************************************************
                  | Your Syptoms define Type 1 diabetes                                                                      
                  |************************************************************************************************
		          | - The development of type 1 diabetes is usually sudden and dramatic.                    
                  | - While the symptoms can often be mild or absent in people with type 2 diabetes                                           
                  | - Making this type of diabetes hard to detect.
                  | - If you show these signs and symptoms, consult a health professional.				  
                  *************************************************************************************************'),100). 

rule(fix(coronary_heart_disease, '
                  |************************************************************************************************
                  | Your Syptoms define Coronary Heart Disease                                                                     
                  |************************************************************************************************
		        | - This syptoms are very sudden and should be handeled with a Medical special                    
                  | - You should immediately contact your doctor                                          			  
                  *************************************************************************************************'),100). 

% askable descriptions
askable(hight_fever).
askable(headache(_)).
askable(profuse_sweeting).
askable(vomiting(_)).
askable(stomach_pain).
askable(musle_pain).
askable(sore_throat).
askable(chest_pain(_)).
askable(heart_attack).
askable(rhythm_disturbances(_)).
askable(frequent_urination).
askable(increased_hunger).
askable(unplanned_weight_loss).
askable(slow_healing_wounds).
askable(blurred_vision).
askable(frequent_infections).
askable(shaking_chills_that_can_range_from_moderate_to_severe).  
askable(bleeding_inside_the_body_as_well_as_eyes_ears_nose).    
askable(pressure_in_the_chest_at_the_time_of_increased_activity). 