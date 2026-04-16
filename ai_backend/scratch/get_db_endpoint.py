import boto3
client = boto3.client('rds', region_name='us-east-1')
try:
    res = client.describe_db_instances()
    for i in res['DBInstances']:
        if i.get('DBClusterIdentifier') == 'egyptian-tourism-ai-deployment-test-cluster':
            print(f"ID: {i['DBInstanceIdentifier']}")
            print(f"Address: {i['Endpoint']['Address']}")
            print(f"Role: {'Writer' if i.get('Status') == 'available' else i.get('Status')}") # This is incomplete, let's use clusters
    
    print("\n--- CLUSTERS ---")
    res_clusters = client.describe_db_clusters(DBClusterIdentifier='egyptian-tourism-ai-deployment-test-cluster')
    for c in res_clusters['DBClusters']:
        print(f"Cluster: {c['DBClusterIdentifier']}")
        for member in c['DBClusterMembers']:
            print(f"Member: {member['DBInstanceIdentifier']}, IsClusterWriter: {member['IsClusterWriter']}")

except Exception as e:
    print(f"Error: {e}")
