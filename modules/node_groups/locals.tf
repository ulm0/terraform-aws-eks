locals {
  # Merge defaults and per-group values to make code cleaner
  node_groups_expanded = { for k, v in var.node_groups : k => merge(
    {
      desired_capacity                     = var.workers_group_defaults["asg_desired_capacity"]
      iam_role_arn                         = var.default_iam_role_arn
      instance_types                       = [var.workers_group_defaults["instance_type"]]
      key_name                             = var.workers_group_defaults["key_name"]
      launch_template_id                   = var.workers_group_defaults["launch_template_id"]
      launch_template_version              = var.workers_group_defaults["launch_template_version"]
      set_instance_types_on_lt             = false
      max_capacity                         = var.workers_group_defaults["asg_max_size"]
      min_capacity                         = var.workers_group_defaults["asg_min_size"]
      subnets                              = var.workers_group_defaults["subnets"]
      create_launch_template               = false
      bootstrap_env                        = {}
      kubelet_extra_args                   = var.workers_group_defaults["kubelet_extra_args"]
      disk_size                            = var.workers_group_defaults["root_volume_size"]
      disk_type                            = var.workers_group_defaults["root_volume_type"]
      disk_iops                            = var.workers_group_defaults["root_iops"]
      disk_throughput                      = var.workers_group_defaults["root_volume_throughput"]
      disk_encrypted                       = var.workers_group_defaults["root_encrypted"]
      disk_kms_key_id                      = var.workers_group_defaults["root_kms_key_id"]
      enable_monitoring                    = var.workers_group_defaults["enable_monitoring"]
      eni_delete                           = var.workers_group_defaults["eni_delete"]
      public_ip                            = var.workers_group_defaults["public_ip"]
      pre_userdata                         = var.workers_group_defaults["pre_userdata"]
      additional_security_group_ids        = var.workers_group_defaults["additional_security_group_ids"]
      taints                               = []
      timeouts                             = var.workers_group_defaults["timeouts"]
      update_default_version               = true
      ebs_optimized                        = null
      metadata_http_endpoint               = var.workers_group_defaults["metadata_http_endpoint"]
      metadata_http_tokens                 = var.workers_group_defaults["metadata_http_tokens"]
      metadata_http_put_response_hop_limit = var.workers_group_defaults["metadata_http_put_response_hop_limit"]
      ami_is_eks_optimized                 = true
    },
    var.node_groups_defaults,
    v,
  ) if var.create_eks }

  node_groups_names = { for k, v in local.node_groups_expanded : k => lookup(
    v,
    "name",
    lookup(
      v,
      "name_prefix",
      join("-", [var.cluster_name, k])
    )
  ) }

  bottlerocket_workers_userdata = {
    for k, v in local.node_groups_expanded : k => templatefile(format("%s/templates/userdata.toml.tpl", path.module), {
      cluster_name             = var.cluster_name
      endpoint                 = var.cluster_endpoint
      cluster_auth_base64      = var.cluster_auth_base64
      enable_admin_container   = lookup(each.value, "enable_admin_container", false)
      enable_control_container = lookup(each.value, "enable_control_container", true)
      additional_userdata      = lookup(each.value, "additional_userdata", "")
    }) if v["create_launch_template"] && length(split("BOTTLEROCKET", v["ami_type"])) > 1
  }
}
