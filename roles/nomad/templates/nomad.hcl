# Managed by Ansible

data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

{% if nomad_advertise_addr %}
advertise {
  http = "{{ nomad_advertise_addr }}"
  rpc  = "{{ nomad_advertise_addr }}"
  serf = "{{ nomad_advertise_addr }}"
}
{% endif %}

region     = "{{ nomad_client_region }}"
datacenter = "{{ nomad_client_dc }}"

server {
  enabled = {{ 'true' if nomad_server_join | length > 0 else 'false' }}

{% if nomad_server_join | length > 0 %}
  bootstrap_expect = {{ nomad_server_join | length }}
  server_join {
    retry_join = {{ nomad_server_join | to_json }}
  }

  # For existing clusters: nomad operator scheduler set-config -memory-oversubscription=true
  default_scheduler_config {
    memory_oversubscription_enabled = true
  }
{% endif %}
}

client {
  enabled = {{ 'true' if nomad_client_join | length > 0 else 'false' }}

{% if nomad_client_node_pool %}
  node_pool = "{{ nomad_client_node_pool }}"
{% endif %}

{% if nomad_network_iface is defined and nomad_network_iface %}
  network_interface = "{{ nomad_network_iface }}"
{% endif %}

{% if nomad_client_join | length > 0 %}
  server_join {
    retry_join = {{ nomad_client_join | to_json }}
  }
{% endif %}

{% if nomad_client_meta | length > 0 %}
  meta {
{% for key, value in nomad_client_meta.items() %}
    {{ key }} = "{{ value }}"
{% endfor %}
  }
{% endif %}

  {{ nomad_client_config | indent(2) }}
}
