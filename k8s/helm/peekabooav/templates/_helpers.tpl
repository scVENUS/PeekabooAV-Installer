{{/*
Expand the name of the chart.
*/}}
{{- define "peekabooav.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "peekabooav.fullname" -}}
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
{{- define "peekabooav.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "peekabooav.labels" -}}
helm.sh/chart: {{ include "peekabooav.chart" . }}
{{ include "peekabooav.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "peekabooav.selectorLabels" -}}
app.kubernetes.io/name: {{ include "peekabooav.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "peekabooav.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "peekabooav.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Format a two-level dictionary into Peekaboo's config file syntax including the
special list option notation. Used to create config drop files for storage in
configMaps or secrets.
*/}}
{{- define "peekabooav.config" }}
{{-   range $section, $optionspec := . }}
{{- /*  // start the section */}}
[{{     $section }}]
{{-     range $option, $value := $optionspec }}
{{-       if kindIs "slice" $value }}
{{- /*      // reset list and start over */}}
{{          $option }}.-: -
{{-         $num := 1 }}
{{-         range $value }}
{{            $option }}.{{ $num }}: {{ . }}
{{-           $num = add $num 1 }}
{{-         end }}
{{-       else }}
{{          $option }}: {{ $value }}
{{-       end }}
{{-     end }}
{{/*    add a newline between sections */}}
{{-   end }}
{{- end }}
