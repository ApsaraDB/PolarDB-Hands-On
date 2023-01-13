# Deploy and Run Superset with PolarDB for PostgreSQL on Alibaba Cloud

## Overview

[Superset](https://superset.apache.org/) is a modern data exploration and visualization platform. This solution deploys Superset on Alibaba Cloud to enhance the high availability of Alibaba Cloud database family.

This solutuion uses the Superset image in Alibaba Cloud Marketplace, which is well packaged and configured for easy starting and future version upgrading. For detailed information of this Superset image, please refer to [Superset Administrator Guide](https://support.websoft9.com/en/docs/superset).

Deployment architecture:

![arch](./images/archi.png)

## Step 1. Use Terraform to Provision ECS Image and Database on Alibaba Cloud

If you are the 1st time to use Terraform, please refer to [here](https://github.com/alibabacloud-howto/terraform-templates) to learn how to install and use the Terraform on different operating systems.

Run the [terraform script](https://github.com/alibabacloud-howto/opensource_with_apsaradb/blob/main/apache-superset/deployment/terraform/main.tf) to initialize the resources. Within the terraform script, please use the right `Image ID` of [Superset image on the corresponding region](https://marketplace.alibabacloud.com/products/56698003/Apache_em_Superset_em_on_Ubuntu-sgcmjj00025684.html).

![superset-image](./images/superset_image.png)

![superset-image-in-tf](./images/superset_image_in_tf.png)

After the Terraform script execution, open the following URL in a Web browser to initialize Superset:

```bash
http://<ECS_EIP>
```

![tf-done](./images/tf_done.png)

Please log on to ECS and visit the Superset credential file to get the initial administrator username and password. By default, the password is `N1cetest`, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>

vim /credentials/password.txt
```

![ecs-logon](./images/ecs_logon.png)

![superset-password](./images/superset_password.png)

Then back to Superset log on page, and input the administrator user name and password to log on, you will see the main page.

![superset-logon](./images/superset_logon.png)

![superset-main](./images/superset_main.png)

## Step 2. Setup Connection to PolarDB for PostgreSQL

On the Superset web page, go to `Data` -> `Databases` to add PolarDB for PostgreSQL as a database.

![pg-config](./images/rds_pg_config.png)

In the `SQLALCHEMY URI`, input the URI of PolarDB for PostgreSQL following this pattern: `postgresql://<username>:<password>@<polardb_pg_domain>:<polardb_pg_port>/<schema>`, such as `postgresql://superset:superset@pc-gs5n44yc841r4y5y70490-public.pg.polardb.singapore.rds.aliyuncs.com:1921/superset`.

Then you can setup `Dataset`, `Chart`, `Dashboard` or work with other BI features on Superset.
