# A terraform module and wrapper shell scripts for managing AWS RDS instances for Oracle

## Instructions to provision a MultiAZ instance of RDS for Oracle
### Pre-requisites
1) The AWS profile is configured on the machine from which the deployment scripts are run (For example 
```
aws configure
```
2) An S3 bucket in the region of the DB deployment, for which the aws credentials used in step 1 has get, put and list permissions

### Create a profile tfvars file using the profiles/rds-oracle.tfvars.example as a reference
#### For instance
```
cp profiles/rds-oracle.tfvars.example profiles/rds-oracle.tfvars
```
#### Edit the the values in the tfvars file appropriately.

#### Run the deployment script like so ...
```
./deploy.sh -c all -p rds-oracle
```
## Instructions to deprovision the RDS instance and associated resources created via the deployment script
```
./teardown.sh -c all -p rds-oracle
```
