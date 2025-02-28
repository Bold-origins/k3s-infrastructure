# Prometheus Stack Reference Files

This directory contains reference files related to the Prometheus Stack deployment.

## Files

- `prometheus-values.yaml`: Complete default values for the kube-prometheus-stack Helm chart (version 69.6.0)

## Purpose

These files are kept for reference purposes when making configuration changes to the Prometheus Stack. 
They provide insight into available configuration options and default values.

## Usage

When making changes to the HelmRelease in the parent directory, refer to these files to understand 
configuration options and their default values.

Do not edit these files directly, as they are not used in the actual deployment. Instead, make changes 
to the `helmrelease.yaml` file in the parent directory. 