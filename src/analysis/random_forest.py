#!/bin/python

import sys

import json

#/home/joseph/source_code/GitView/src/analysis/data/train_data_sample_facebook_fresco_0.5_70_70_2
# Get training json file
# Get testing json file
training_file = sys.argv[1]

testing_file = sys.argv[2]

output_performance = sys.argv[3]
output_importance = sys.argv[4]

f = open(training_file, 'r')
training_raw = f.read()

training_data = json.loads(training_raw)

f = open(testing_file, 'r')
testing_raw = f.read()

testing_data = json.loads(testing_raw)

#from sklearn.cross_validation import cross_val_score
from sklearn.ensemble import RandomForestClassifier

X = training_data["data"]
Y = training_data["categories"]

clf = RandomForestClassifier(n_estimators=10000)

#scores = cross_val_score(clf, X, Y)

clf = clf.fit(X, Y)

prediction_results = clf.predict(testing_data["data"])

true_positive = 0
false_positive = 0
true_negative = 0
false_negative = 0

# Compare the list of results to the actual results
for i in range(len(prediction_results)):
    print ("predicted", prediction_results[i], "actual", testing_data["categories"][i])
    if prediction_results[i] == testing_data["categories"][i]:
        print("Passed - predicted", prediction_results[i], "actual", testing_data["categories"][i], ":", testing_data["data"][i])
        if prediction_results[i] == 1.0:
            true_positive += 1
        else:
            true_negative += 1
    else:
        print("Failed - predicted", prediction_results[i], "actual", testing_data["categories"][i], ":", testing_data["data"][i])

        if prediction_results[i] == 1.0:    
            false_positive += 1
        else:
            false_negative += 1

print training_file
print testing_file

importance_values = clf.feature_importances_


#print "Mean Score:", scores
print "Importance:", importance_values

#import numpy as np

importance_file = open(output_importance, 'a')

importance_file.write(str(importance_values).replace('\n', '') + '\n')

importance_file.close()


print("true_positive", true_positive)
print("false_positive", false_positive)
print("true_negative", true_negative)
print("false_negative", false_negative)

precision = (true_positive) / float(true_positive + false_positive)
recall = (true_positive) / float(true_positive + false_negative)
accuracy = (true_positive + true_negative) / float(true_positive + true_negative + false_positive + false_negative)

print "Precision:", true_positive, "/", (true_positive + false_positive), "=", precision

print "Recall:", true_positive, "/", (true_positive + false_negative), "=", recall

print "Accuracy:", (true_positive + true_negative), "/", (true_positive + true_negative + false_positive + false_negative), "=", accuracy

performance_file = open(output_performance, 'a')

performance_file.write(str(precision) + ', ' + str(recall) + ', ' + str(accuracy) + '\n')

performance_file.close()
