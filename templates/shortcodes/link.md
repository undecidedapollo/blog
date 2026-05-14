{%- if path -%}
{%- set href = get_url(path=path) -%}
{%- else -%}
{%- set href = url -%}
{%- endif -%}
{%- set display = href | split(pat="#") | first | trim_start_matches(pat="https://") | trim_start_matches(pat="http://") | trim_start_matches(pat="www.") -%}
\[[{{ label }}]({{ href | safe }})\]\([{{ display }}]({{ href | safe }})\)
