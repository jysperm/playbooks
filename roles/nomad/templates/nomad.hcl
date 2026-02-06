# Managed by Ansible

data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

region     = "{{ nomad_client_region }}"
datacenter = "{{ nomad_client_datacenter }}"

server {
  enabled = {{ 'true' if nomad_server_join | length > 0 else 'false' }}
{% if nomad_server_join | length > 0 %}
  bootstrap_expect = {{ nomad_server_join | length }}
  server_join {
    retry_join = {{ nomad_server_join | to_json }}
  }
  default_scheduler_config {
    memory_oversubscription_enabled = true
  }
{% endif %}
}

client {
  enabled = {{ 'true' if nomad_client_join | length > 0 else 'false' }}
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
