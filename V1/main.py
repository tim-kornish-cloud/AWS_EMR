# Author: Timothy Kornish
# CreatedDate: 9/06/2025
# Description: set up a pyspark session to load the csv into and process
# follows youtube tutorial: https://www.youtube.com/watch?v=8bOgOvz6Tcg&list=PLkbxKqEYgUFSDTNZ0LoTLWfPNBd7D3-iZ&index=11
# data set from: https://data.kingcounty.gov/Health-Wellness/Food-Establishment-Inspection-Data/f29f-zza5/about_data

#spark for loading and processing data
from pyspark.sql import SparkSession
from pyspark.sql.functions import col
# argparse for running script when called
import argparse

def update_headers(df, column_mapping):
    """
        Description: Update the column headers of a dataframe
        Parameters:

        df                  - spark dataframe
        column_mapping      - dictionary, key = old name, value = new name

        Return:             - spark dataframe, with new column headers
        """
    # copy df to not modify in place
    df_renamed_dict = df
    # loop through each key:value pair to update column headers
    for old_name, new_name in column_mapping.items():
        # replace single column header with new column header 
        df_renamed_dict = df_renamed_dict.withColumnRenamed(old_name, new_name)
    # return the renamed df based on dict values
    return df_renamed_dict

def load_transform_data(data_source, query = None, output_s3_uri = None, app_name = "First Spark Application"):
    """
        Description: load data source into a spark session to perform operations on the dataset
        Parameters:

        data_source     - string, name of file to be uploaded to spark
        query           - string, SQL query to isolate specific data in dataset
        output_s3_uri   - uri to send outputs to
        appName         - string, set the name of the spark app

        Return: sf      - none
        """
    # initialize a spark session to load data into
    with SparkSession.builder.appName(app_name).getOrCreate() as spark:
        # upload the csv data into the spark session
        df = spark.read.option("header", "true").csv(data_source)
        # modify the column names using col and .alias, original way shown in tutorial
        """
        df = df.select(
            col("Name").alias("name"),
            col("Violation Type").alias("violation_type")
        )
        """
        # create column header mapping to update the column header names 
        column_mapping = {
        "Name": "name",
        "Violation Type": "violation_type",
        }
        # update the column headers of the original dataframe
        df = update_headers(df, column_mapping)
        # create a temporary view of the csv to perform queries off of
        df.createOrReplaceTempView("restaurant_violations")
        # set up group by query to analyze number of violations per location
        GROUP_BY_QUERY = """
            SELECT name, count(*) as total_red_violations
            FROM restaurant_violations
            WHERE violation_type = "Red"
            GROUP BY name
            HAVING total_red_violations > 1
        """
        # use default sql if none provided:
        if query is None:
            query = GROUP_BY_QUERY
        # retrieve the group by query results and load into new variable dataframe
        violations_df = spark.sql(query)
        # log the queried results to the EMR stdout
        print(f"Number of rows in SQL query: {violations_df.count()}")
        #write our results as parquet files
        violations_df.write.mode("overwrite").parquet(output_s3_uri)

if __name__ == "__main__":
    # set up arg parser to accept console arguments when ran in EMR console
    parser = argparse.ArgumentParser()
    # add arg for data source, must be included when running script, not optional
    parser.add_argument("data_source")
    # add arg for query
    parser.add_arguemnt("--query")
    # add arg for the s3 bucket log folder
    parser.add_argument("--output_s3_uri")
    # add arg for app name on EMR
    parser.add_argument("--app_name")
    # parse the arguments passed in the console
    args = parser.parse_args()
    # execute the script on EMR
    load_transform_data(args.data_source, args.query , args.output_s3_uri , args.app_name)