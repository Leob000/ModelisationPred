# Checklist from Hands-On ML book by Aurélien Géron

## Frame the problem and look at the big picture  
1. Define the objective in business terms.  
- Predict Load or Net_demand ?
- Load : Conso d'électrécité
- Net demand : Conso d'électrécité - Production locale (panneaux solaires, ...) -> plus faible que Load
- Train sur les données de "2013-03-02" à "2022-09-01", test de "2022-09-02" à "2023-10-01", donc période spéciale de sobriété
    - Intérêt fort de prévoir la demande durant cette période à cause des prix très élevés
    - Période de sobriété énergique à cause de différents facteurs (guerre en Ukraine, réparations centrales nucléaires)
    - Plan de sobriété national présenté le 6 octobre 2022 et effectif à partir de juin 2022, voir [lien du gouvernement ](https://www.ecologie.gouv.fr/actualites/sobriete-energetique-plan-reduire-notre-consommation-denergie).
    - Objectif du gouvernement de réduction de 10% de la consommation d'énergie sur 2 ans (à partir du plan) par rapport à 2019

<!-- 2. How will your solution be used?   -->
<!-- 3. What are the current solutions/workarounds (if any)?   -->
4. How should you frame this problem (supervised/unsupervised, online/offline, etc.)  
- Supervised, offline
5. How should performance be measured?  
- Pinball loss quantile 0.8
- Grosse erreur si on sous-estime la pred, plus petite si on sur-estime
- Donc revient à estimer le quantile 0.8
6. Is the performance measure aligned with the business objective?  
- Oui, car gros problème si on ne parvient pas à répondre à la demande (amendes, blackout, prix d'achat très élevé à l'étranger car tout le monde dans la galère?), moins gros si on a juste de l'électricité en trop (juste moins bonne optimisation ?)
<!-- 7. What would be the minimum performance needed to reach the business objective?   -->
<!-- 8. What are comparable problems? Can you reuse experience or tools?   -->
<!-- 9. Is human expertise available?   -->
10. How would you solve the problem manually?  
- Moyennes des conso des moments des années précédentes + réserve pour réduire le risque de ne pas pouvoir répondre à la demande
<!-- 11. List the assumptions you or others have made so far.   -->
<!-- 12. Verify assumptions if possible.   -->

<!-- ## Get the data   
Note: automate as much as possible so you can easily get fresh data.  

1. List the data you need and how much you need.  
2. Find and document where you can get that data.  
3. Check how much space it will take.  
4. Check legal obligations, and get the authorization if necessary.  
5. Get access authorizations.  
6. Create a workspace (with enough storage space).  
7. Get the data.  
8. Convert the data to a format you can easily manipulate (without changing the data itself).  
9. Ensure sensitive information is deleted or protected (e.g., anonymized). 
10. Check the size and type of data (time series, sample, geographical, etc.).  
11. Sample a test set, put it aside, and never look at it (no data snooping!).     -->

## Explore the data  
Note: try to get insights from a field expert for these steps.  

1. Create a copy of the data for exploration (sampling it down to a manageable size if necessary).
2. Create a Jupyter notebook to keep record of your data exploration.  
3. Study each attribute and its characteristics:  
    - Name  
    - Type (categorical, int/float, bounded/unbounded, text, structured, etc.)
    - % of missing values  
    - Noisiness and type of noise (stochastic, outliers, rounding errors, etc.)
    - Possibly useful for the task?  
    - Type of distribution (Gaussian, uniform, logarithmic, etc.)
Load.1 le load décalé d'un jour
Temp_s95 température avec lissage exponentiel
Temp_S95_min minimum de la température lissée sur la journée
Nébulosité, a quel point le ciel est opaque (100 = très nuageux)
Nebulosity_weighted prend en compte les panneaux solaires
toy = time of year
weekdays = jour de la semaine (à modifier)
BH bank holidays = jour férié ; before/after si before/after l'est aussi
DLS Day light savings, changement d'heure
summer break Mois d'août

Température ressentie dépend de wind et temp
Tester faire des modèles séparés pour la production et la conso?
Faire ensemble de modèle avec 1 modèle qui sous-estime et 1 qui sur-estime
4. For supervised learning tasks, identify the target attribute(s).
5. Visualize the data.  
6. Study the correlations between attributes.  
7. Study how you would solve the problem manually.  
8. Identify the promising transformations you may want to apply.  
9. Identify extra data that would be useful (go back to "Get the Data" on page 502).  
10. Document what you have learned.  

## Prepare the data  
Notes:    
- Work on copies of the data (keep the original dataset intact).  
- Write functions for all data transformations you apply, for five reasons:  
    - So you can easily prepare the data the next time you get a fresh dataset  
    - So you can apply these transformations in future projects  
    - To clean and prepare the test set  
    - To clean and prepare new data instances  
    - To make it easy to treat your preparation choices as hyperparameters  

1. Data cleaning:  
    - Fix or remove outliers (optional).  
    - Fill in missing values (e.g., with zero, mean, median...) or drop their rows (or columns).  
2. Feature selection (optional):  
    - Drop the attributes that provide no useful information for the task.  
3. Feature engineering, where appropriates:  
    - Discretize continuous features.  
    - Decompose features (e.g., categorical, date/time, etc.).  
    - Add promising transformations of features (e.g., log(x), sqrt(x), x^2, etc.).
    - Aggregate features into promising new features.  
4. Feature scaling: standardize or normalize features.  

## Short-list promising models  
Check Kaggle timeseries course + Kaggle winning models
Generalized Random Forest
Notes: 
- If the data is huge, you may want to sample smaller training sets so you can train many different models in a reasonable time (be aware that this penalizes complex models such as large neural nets or Random Forests).  
- Once again, try to automate these steps as much as possible.    

1. Train many quick and dirty models from different categories (e.g., linear, naive, Bayes, SVM, Random Forests, neural net, etc.) using standard parameters.  
2. Measure and compare their performance.  
    - For each model, use N-fold cross-validation and compute the mean and standard deviation of their performance. 
3. Analyze the most significant variables for each algorithm.  
4. Analyze the types of errors the models make.  
    - What data would a human have used to avoid these errors?  
5. Have a quick round of feature selection and engineering.  
6. Have one or two more quick iterations of the five previous steps.  
7. Short-list the top three to five most promising models, preferring models that make different types of errors.  

## Fine-Tune the System  
Notes:  
- You will want to use as much data as possible for this step, especially as you move toward the end of fine-tuning.   
- As always automate what you can.    

1. Fine-tune the hyperparameters using cross-validation.  
    - Treat your data transformation choices as hyperparameters, especially when you are not sure about them (e.g., should I replace missing values with zero or the median value? Or just drop the rows?).  
    - Unless there are very few hyperparamter values to explore, prefer random search over grid search. If training is very long, you may prefer a Bayesian optimization approach (e.g., using a Gaussian process priors, as described by Jasper Snoek, Hugo Larochelle, and Ryan Adams ([https://goo.gl/PEFfGr](https://goo.gl/PEFfGr)))  
2. Try Ensemble methods. Combining your best models will often perform better than running them invdividually.  
3. Once you are confident about your final model, measure its performance on the test set to estimate the generalization error.

> Don't tweak your model after measuring the generalization error: you would just start overfitting the test set.  
  
## Present your solution  
1. Document what you have done.  
2. Create a nice presentation.  
    - Make sure you highlight the big picture first.  
3. Explain why your solution achieves the business objective.  
4. Don't forget to present interesting points you noticed along the way.  
    - Describe what worked and what did not.  
    - List your assumptions and your system's limitations.  
5. Ensure your key findings are communicated through beautiful visualizations or easy-to-remember statements (e.g., "the median income is the number-one predictor of housing prices").  

## Launch!  
1. Get your solution ready for production (plug into production data inputs, write unit tests, etc.).  
2. Write monitoring code to check your system's live performance at regular intervals and trigger alerts when it drops.  
    - Beware of slow degradation too: models tend to "rot" as data evolves.   
    - Measuring performance may require a human pipeline (e.g., via a crowdsourcing service).  
    - Also monitor your inputs' quality (e.g., a malfunctioning sensor sending random values, or another team's output becoming stale). This is  particulary important for online learning systems.  
3. Retrain your models on a regular basis on fresh data (automate as much as possible).