# Declare variables
variable "resource_group_name" {
    type = string
    default = "Resource Group"
    description = "Name of the resource group"
}
variable "location" {
    type = string
    default = "Central US"
    description = "Location of the resource group"
}
variable "prefix" {
    type = string
    default = "Rate"
    description = "prefix assigned to resource names"
}
variable "admin_username" {
    type = string
    default = "adminuser"
    description = "Username for the admin on the virtual machine"
}
variable "hostname" {
    type = string
    default = "guaranteedrate"
    description = "Public IP hostname"
}
variable "address_prefix" {
    type = string
    default = "10.0.2.0/24"
    description = "Address prefix for the private IP"
}
variable "address_space" {
    type = string
    default = "10.0.0.0/16"
    description = "Address space for the virtual network"
}