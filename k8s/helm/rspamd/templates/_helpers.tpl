{{/*
Expand the name of the chart.
*/}}
{{- define "rspamd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rspamd.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rspamd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rspamd.labels" -}}
helm.sh/chart: {{ include "rspamd.chart" . }}
{{ include "rspamd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rspamd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rspamd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rspamd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rspamd.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Build a list of environment variables recursively from a config dict.
*/}}
{{- define "rspamd.configEnvVars" -}}
{{-   $vars := dict }}
{{/*  // has to be extracted here because context changes in loops below */}}
{{-   $prefix := .prefix }}
{{-   range $key, $value := .config }}
{{-     if kindIs "map" $value }}
{{/*      // recurse into maps (aka dicts */}}
{{-       $newprefix := printf "%s%s__" $prefix $key }}
{{-       $parameters := dict "prefix" $newprefix "config" $value }}
{{-       $newvars := include "rspamd.configEnvVars" $parameters | mustFromJson }}
{{-       $vars := mustMerge $vars $newvars }}
{{-     else if kindIs "slice" $value }}
{{/*      // generate special var name syntax for arrays/lists/slices */}}
{{-       $num := 1 }}
{{-       range $value }}
{{-         if kindIs "string" . }}
{{-           $name := printf "%s%02d_%s_" $prefix $num $key }}
{{-           $vars = set $vars $name . }}
{{-         else }}
{{-           $name := printf "%s%02d_%s" $prefix $num $key }}
{{-           $vars = set $vars $name (toString .) }}
{{-         end }}
{{-         $num = add $num 1 }}
{{-       end }}
{{-     else if kindIs "string" $value }}
{{-       $name := printf "%s%s_" $prefix $key }}
{{-       $vars = set $vars $name $value }}
{{-     else }}
{{-       $name := printf "%s%s" $prefix $key }}
{{-       $vars = set $vars $name (toString $value) }}
{{-     end }}
{{-   end }}
{{/*  // we have to communicate complex return data structure via JSON */}}
{{-   mustToJson $vars }}
{{- end }}
