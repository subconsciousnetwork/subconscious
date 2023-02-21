# Subconscious

## Setup

Install [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12), clone the repo and open the project.

## Config

Common application config is set in `Config.swift`, set `debug` to `true` for local development.

## Running on Device

- Enable Developer Mode on the target device
  - Settings -> Security & Privacy -> Developer Mode
- Connect device
  - Wait for Xcode to detect it
- Run build (fails)
  - Change the build target to your device
  - It should warn you that you're missing a provisioning profile
- Add Developer Account
  - Sign in with your Apple ID (you can create a new one just for this)
- Change App Identifier
  - The `com.subconscious.Subconscious` identifier is covered by the team provisioning profile so you'll need to make your own, i.e. `com.my-username.Subconscious`
- Automatically Create Provisioning Profile
  - After changing the identifier XCode should configure provisioning for you
- Build & Run again
- Trust App
  - On device visit Settings -> General -> VPN & Device Managment to trust the app