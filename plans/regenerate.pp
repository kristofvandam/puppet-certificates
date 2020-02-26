plan certificates::regenerate (
  TargetSpec         $master,
  TargetSpec         $targets,
  Optional[Boolean]  $restore             = false,
  Optional[Hash]     $custom_attributes   = {},
  Optional[Hash]     $extension_requests  = {},
) {

  # Extract the Target name from $webservers
  get_targets($targets).map |$target| {
    run_task('certificates::attributes', $target,
      restore => $restore,
    	custom_attributes => $custom_attributes, 
    	extension_requests => $extension_requests,
    	_catch_errors => true
    )
    run_task('certificates::revoke', $master,
      restore => $restore,
      target => "${target}",
      _catch_errors => true
    )
    run_task('certificates::request', $target,
      restore => $restore,
      _catch_errors => true
    )
    #run_task('certificates::sign')
  }

 }