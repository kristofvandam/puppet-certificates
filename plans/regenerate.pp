plan certificates::regenerate (
  TargetSpec         $master,
  TargetSpec         $targets,
  Optional[Boolean]  $force               = false,
  Optional[Boolean]  $restore             = false,
  Optional[Hash]     $custom_attributes   = {},
  Optional[Hash]     $extension_requests  = {},
) {

  # Extract the Target name from $webservers
  get_targets($targets).map |$target| {

   without_default_logging() || {
      # apply($target, _catch_errors => true) {
      #   file { '/tmp/ruby':
      #     ensure  => file,
      #     mode    => '0700',
      #     content => template('certificates/ruby_interpreter.sh')
      #   }
      # }
      out::message("  Started     : ${target}")

      $task_attributes = run_task('certificates::attributes', $target,
        restore            => $restore,
        custom_attributes  => $custom_attributes,
        extension_requests => $extension_requests,
        _catch_errors      => true
      ).first

      if ($task_attributes['status'] == 'changed' or $force == true) {

        if ($force == true) {
          out::message("  - Attributes: No changes but generation is forced")
        } else {
          out::message("  - Attributes: Changed, continueing")
        }

        $task_revoke = run_task('certificates::revoke', $master,
          restore       => $restore,
          target        => "${target}",
          _catch_errors => true
        ).first

        if ($task_revoke['status'] == 'changed') {
          out::message("  - Revoked   : Certificate found and revoked")
        }

        $task_request = run_task('certificates::request', $target,
          restore       => $restore,
          _catch_errors => true
        ).first

          out::message("  - Requested : ok")
        # if ($task_request['status'] == 'changed') {
        # }

        $task_sign = run_task('certificates::sign', $master,
          restore       => $restore,
          target        => "${target}",
          _catch_errors => true
        ).first

        if ($task_sign['status'] == 'changed') {
          out::message("  - Signed    : ok")
        }

      } else {
        out::message("  - Skipped   : no change on the csr_attributes.yaml file")
      }
    }
  }

}