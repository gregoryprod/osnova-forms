# No form bodies, query values or CRM responses in application logs.
Rails.application.config.filter_parameters += [ /./ ]
