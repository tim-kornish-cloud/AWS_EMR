# Author: Timothy Kornish
# CreatedDate: 9/06/2025
# Description: set up a pyspark
# follows youtube tutorial: https://www.youtube.com/watch?v=8bOgOvz6Tcg&list=PLkbxKqEYgUFSDTNZ0LoTLWfPNBd7D3-iZ&index=11
# data set from: https://data.kingcounty.gov/Health-Wellness/Food-Establishment-Inspection-Data/f29f-zza5/about_data

from pyspark.sql import SparkSession
from pyspark.sql.functions import col

def transform_data(data_source, output_s3_uri):
    with SparkSession.builder.appName("First Spark Application").getOrCreate() as spark:
