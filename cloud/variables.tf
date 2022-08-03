variable "ssh_key_path" {
  type        = string
  description = "The file path to an SSH public key."
  default     = "~/.ssh/id_ed25519.pub"
}
