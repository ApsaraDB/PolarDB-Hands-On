
# Overview


## Machine learning is _vital_ to many real-world applications
Without machine learning, many applications driven by data intelligence would not be possible. Machine learning models have recently gained a lot of  attention, as they are able to do classifications, regressions, or clusterings, and uncover valuable and fine-grained insights. These insights subsequently drive decision-making in many real-world applications, impacting key growth metrics for businesses. For example, recommendation systems use Click-through Rate (CTR) prediction models to selectively exhibit items to end-users and gain more profit; a robust defect-detection model, getting aligned with domain experts for the identification of defects, is able to eliminate defective products at the early stage; a named entity recognition model extracts entities from text snippets and helps a search engine accurately retrieve relevant documents, leading to stable user growth.

## A machine learning pipeline can be _tedious_ and _error-prone_
Compared with conventional data analytic jobs, nevertheless, such a data analytic job related to machine learning usually calls for a tedious and error-prone pipeline. For example, as shown in the figure below, in order to produce a CTR model, people need to export the user data, item data, and behavior data from a database using SQL statements, apply sophisticated data transformations using python scripts and/or JAVA programs, train a CTR prediction model with the help of a machine learning framework (e.g., TensorFlow), evaluate the model and adjust its parameters, and then deploy the model online for CTR prediction.


<div align="center">
<img src=imgs/machine-learning-pipeline.png width=600 />
</div>

## In-database machine learning could be a _solution_
Clearly, such a pipeline is complicated. As a result, many small or medium-sized enterprises may suffer from it. On one hand, many different roles, including the database administrator, the data analyst, and the algorithm engineer, have to take part; on the other hand, many intermediate results, including features and models, need to be well-organized and maintained. To address these issues, a new paradigm that combines database systems, feature engineering techniques, and machine learning frameworks is expected. Accordingly, in-database machine learning has become a hot topic, attracting attention from both academia and industry. In academia, researchers try to fill the gap among relational algebra, feature engineering, and model computation, while in industry, pioneers attempt to lower the barriers of feature engineering, model management, and model deployment for skilled database users.


## _PolarDB_ _for_ _AI_ is an in-database machine learning system 
Aiming at a one-stop in-database machine learning solution, PolarDB for AI (PDAI) was devised[1] and developed as a module of PolarDB. PDAI provides in-database feature engineering, in-database machine learning, and in-database model deployment capabilities with a collection of well-designed and user-friendly SQL templates. Some SQL templates corresponding to feature engineering include feature creation, feature update, feature deletion, and feature status checking; some SQL templates corresponding to machine learning and model deployment include model creation, model training, model evaluation, model prediction, model upload, model download, model deletion, model listing, and model status checking. Based on these generalized operations, a database user can easily perform feature engineering and machine learning using SQL statements.

[1] Qiuru Lin, Sai Wu, Junbo Zhao, Jian Dai, Feifei Li, Gang Chen:
A Comparative Study of in-Database Inference Approaches. ICDE 2022: 1794-1807

<div align="center">
<img src=imgs/polardb-for-ai-arch.png width=600 />
</div>


As shown in the figure above, a PolarDB instance equipped with the PolarDB for AI module contains in-database feature engineering, in-database model management, and in-database model deployment and serving capabilities. A database user can easily access these capabilities with SQL statements that follow the pre-defined SQL templates. In the following, we shall demonstrate 1) how to use the in-database model management capability; 2) how to use the in-database model deployment and serving capability.


# Quick Start


## Prerequisites

### Step 1: Turn on PolarDB for AI 

First of all, you need to turn on PolarDB for AI, shown on the main page of PolarDB console.

<div align="center">
<img src=imgs/baseinfo-modified.png width=600 />
</div>


Then, a dedicated account is preferably be created for the PolarDB for AI. For example, as shown below, you may create a new account "polar_test" with respect to the database "db4ai" and grant "ReadOnly" permission to the account.

<div align="center">
<img src=imgs/creatAccount-modified.png width=600 />
</div>

After that, you can use the dedicated account to enable PolarDB for AI.

<div align="center">
<img src=imgs/username-modified.png width=600 />
</div>

### Step 2: Connect to PolarDB for AI

You can establish the connection to PolarDB for AI using the MYSQL binary at the command prompt or the integrated development environment. When connecting to a PolarDB instance (or a cluster) with the enabled PolarDB for AI capability, the PolarDB cluster address should be used, instead of the main address.

If you use the MySQL command line to connect to the cluster address, you need to add the -c option to the command to activate the PolarDB for AI syntax. 

```
$> mysql -h PolarDB_cluster_address -u username -p password -c
```

where PolarDB_cluster_address is the public cluster endpoint address, username and password come from the account created in Step 1.

<div align="center">
<img src=imgs/mainaddress-modified.png width=600 />
</div>


## PolarDB for AI: In-database Model Management


When executing a PolarDB for AI SQL statement, you need to add /*polar4ai*/ before the SQL statement.

### Step 1: Create a model

A machine learning model can be created by the following SQL statement template.
(More details can be found at [PolarDB for AI](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/polardb4ai))

```
/*polar4ai*/
CREATE MODEL model_name WITH 
( model_class = '', x_cols = '', y_cols='',model_parameter=()) 
AS 
(SELECT select_expr [, select_expr] ... FROM table_reference)
```
where model_name denotes the user-specified model name; model_class represents the built-in model types (currently, [lightgbm](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/lightgbm), [deepfm](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/deepfm), [kmeans](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/kmeans), [randomforestreg](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/random), [gbrt](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/gbrt), [linearreg](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/linearregression), [svr](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/svr) are supported) supported by PolarDB for AI; x_cols is the input X columns for model creation and training; y_cols is the input Y columns for model creation and training; model_parameter is the  parameter setting for the model. Please refer to the corresponding model for details; select_expr denotes the SQL statement to obtain the training data from the database; table_reference is the table names to obtain the training data from the database.


Here, we give a running example of how to create a model using PolarDB for AI.
First, let's take a look at the concrete data in the db4ai.airlines_train table. The figure below shows 10 rows of the data used in the example. 

```
select * from db4ai.airlines_train LIMIT 10;
``` 

<div align="center">
<img src=imgs/airline-limit10.png width=600 />
</div>

Next, as illustrated below, we can create a model whose name is airline_gbm, model class is lightgbm, and model parameter setting is (boosting_type='gbdt', n_estimators=100, max_depth=8, num_leaves=256), where the training data is selected from the relational table db4ai.airlines_train, the columns 'Airline,Flight,AirportFrom,AirportTo,DayOfWeek,Time,Length' correspond to the X in lightgbm, and column 'Delay' corresponds to the Y in lightgbm.

```
/*polar4ai*/ 
create model airlines_gbm with 
(model_class='lightgbm', 
x_cols ='Airline,Flight,AirportFrom,AirportTo,DayOfWeek,Time,Length', 
y_cols='Delay',
model_parameter=(boosting_type='gbdt', n_estimators=100, max_depth=8, num_leaves=256)) 
as (select * from db4ai.airlines_train);
```

If the model creation is successfully issued, PolarDB for AI returns an OK message.

```
Query OK, 0 rows affected (0.79 sec)
```

As the model creation contains a model training process, it can be time-consuming. As a result, PolarDB for AI schedules it as an offline job. To view the status of the model, you may proceed to issue another show model query.

### Step 2: Check the status of a model

"SHOW MODEL" is used to view the status of a model. 

"SHOW MODEL" Syntax
```
/*polar4ai*/
SHOW MODEL model_name 
```
Here, "model_name" refers to the name of the model created earlier.

For instance, if you want to check the status of the model airlines_gbm created in Step 2.1, you can issue the SQL statement below.

```
/*polar4ai*/
SHOW MODEL airlines_gbm;
```

Alternatively, you can use "SHOW MODELS" to obtain the status of all models, if you have created multiple models and want to view their status at the same time.

"SHOW MODELS" Syntax
```
/*polar4ai*/
SHOW MODELS 
```

As we only have one model, we could use "SHOW MODELS" and "SHOW MODEL" interchangeably.

At first, the model status may be "loading_data", indicating PolarDB for AI is preparing the training data.

<div align="center">
<img src=imgs/loading-data.png width=400 />
</div>

After a while, when the model status returned by "SHOW MODELS" is "saved_oss", the model is ready for use.

<div align="center">
<img src=imgs/saved_oss.png width=400 />
</div>


### Step 3: Use the model to predict

We can use the "PREDICT" SQL statement to perform model prediction when the corresponding model status has become "saved_oss". 

"PREDICT" Syntax
```
/*polar4ai*/
SELECT select_expr [, select_expr] ... FROM 
PREDICT (MODEL model_name, SELECT select_expr_for_prediction 
[, select_expr_for_prediction] ... 
FROM table_reference LIMIT row_count) WITH (x_cols= '')
```
Here, "model_name" refers to the name of the model.

We still use the running example to demonstrate how to use the "PREDICT" SQL statement.
When the model "airlines_gbm" is ready for use, we can use the following SQL statement to perform prediction.

```
/*polar4ai*/ 
select Delay from predict
(model airlines_gbm, select * from db4ai.airlines_test limit 100) 
with 
(x_cols = 'Airline,Flight,AirportFrom,AirportTo,DayOfWeek,Time,Length', 
y_cols='Delay');
```

Here, the term "Delay" denotes the returned column, the SQL clause "select * from db4ai.airlines_test limit 100" retrieves data from table db4ai.airlines_test for prediction, the SQL clause "x_cols = 'Airline,Flight,AirportFrom,AirportTo,DayOfWeek,Time,Length', 
y_cols='Delay'" specifies the X columns and Y columns.

When the computation terminates, the predicted results along with the specified columns "Delay" will be returned, as illustrated below.

<div align="center">
<img src=imgs/predicted_results.png width=900 />
</div>



## PolarDB for AI: In-database Model Deployment

PolarDB for AI has some built-in machine learning models such as KMeans, SVR, lightgbm, etc. Nevertheless, the models used in real-world applications can be varied. In order to support various models, PolarDB for AI supports the uploading of customized models that are created by different machine learning frameworks (such as TensorFlow, Pytorch and sklearn); furthermore, PolarDB for AI uses these customized models as easy as the built-in models, following the same SQL syntax. In the following, we show how to do achieve this in a couple of SQL statements.


### Step 1: Upload a customized model

First, we can upload a customized model using "MODEL UPLOAD".

"MODEL UPLOAD" syntax:
```
/*polar4ai*/
UPLOAD MODEL model_name WITH (model_location = '', req_location = '') 
```
where model_name denotes the model name, model_location specified the location of the model, and req_location is a requirement txt file that contains the used Python libraries.

For example, we can upload a customized model "my_model" that is stored in OSS and uses the requirements.txt as its requirements file, using the SQL statement shown in the figure below.

<div align="center">
<img src=imgs/upload_model.png width=900 />
</div>

When the uploading SQL statement is successfully performed, an OK message will be returned.

### Step 2: Deploy the customized model

After the uploading, you need to deploy the customized model so that it can be correctly identified and used by PolarDB for AI.

First, you need to check the customized model status (e.g. "my_model"), until it becomes "saved_oss", as illustrated in the Figure below.

<div align="center">
<img src=imgs/deploy_model_1.png width=400 />
</div>

Next, you need to deploy the customized model status to PolarDB for AI. Here, "MODEL DEPLOY" is used.

"MODEL DEPLOY" syntax:
```
/*polar4ai*/
DEPLOY MODEL model_name 
```
where model_name refers to the name of the newly uploaded customized model. As shown below, in the running example, the model name is "my_model".

An OK message should be returned when the model is deployed successfully. 

At this moment, when the model status is checked again, it should become "serving", indicating the customized model is ready for serving.

<div align="center">
<img src=imgs/deploy_model_2_serving.png width=400 />
</div>



### Step 3: Use the customized model

When the customized model is ready for serving, you may proceed to use the customized model. In other words, you may use the model for prediction.

Before diving into the customized model prediction, we first take a look at the data stored in a table for prediction. As shown below, the table "regression_test" has 29 columns, where x1-x28 are the features used to predict the values in column Y.

<div align="center">
<img src=imgs/cus_model_limit10.png />
</div>

Same as the built-in models, the customized model can be used by a "PREDICT" SQL statement. As shown below, the SQL statement

```
/*polar4ai*/ 
select Y from predict(model my_model, select * from db4ai.regression_test limit 10) 
with 
(x_cols = 'x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,
x16,x17,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28', y_cols='');
``` 
utilizes the customized model "my_model" to predict the data retrieved from table "regrsssion_test". The predicted results should be returned in the column "predicted_results".

<div align="center">
<img src=imgs/cus_model_predicted_results.png />
</div>

### Step 4: Clean up

To end this running example, you may delete the models created or uploaded eariler. You can delete them by "DROP MODEL" SQL statements.

"DROP MODEL" syntax:
```
/*polar4ai*/
DROP MODEL model_name 
```
where model_name denotes the model name.


As shown below, you may delete the model "arilines_gbm" and "my_model" using drop model statements. After the deletion, show models should return an empty set.

<div align="center">
<img src=imgs/cleanup.png width=400 />
</div>

## More features

The above steps demonstrate how to perform in-database model management including model creation, model listing, and model prediction, and how to use a customized model in PolarDB for AI. More features such as model description, model evaluation, and feature engineering are provided by PolarDB for AI as well. You may find more details at [PolarDB for AI](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/polardb4ai).
