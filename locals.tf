locals {
    common_tags = { 
        Environment = "Prod"
        Team = "TechOps"
        Account     = "Prod"
        Owner       = "Genevieve"
        RM_Project_Code = "PRODEV_me"
        Classification = "Internal"
        
    }
}


#defining variables for Lambda funtcion
locals {
  lambda_src_dir    = "${path.module}/lambda_functions/"
  lambda_function_zip_path = "${path.module}/lambda_functions/index.zip"
  lambda_function_forecaasting_zip_path = "${path.module}/freemium_function/lambda_function.zip"
}