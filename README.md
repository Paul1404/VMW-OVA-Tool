VMW-OVA-Tool 🛠️📦
==================

A PowerShell script to automate the usage of the VMware OVF Tool, handling installation, credential storage, and dynamic command execution. No need to manually input credentials or install the OVF Tool every time—this script does it all for you! 🎉

Features ✨
----------

* **Automatic OVF Tool Installation**: If the OVF Tool isn't installed, the script will download and install it silently. 💾🔧
* **Secure Credential Storage**: Credentials are encrypted and stored securely. They will be reused on subsequent executions, so no more repetitive typing! 🔐
* **Dynamic Command Creation**: Input your VM path and storage destination, and the script crafts the OVF Tool command dynamically for you. 📝🚀
* **Error Handling**: Smart error handling ensures that the script runs smoothly, providing useful feedback along the way. ⚠️

Installation and Usage 💻
-------------------------

1. **Clone the Repository**:
    
    ```bash
    git clone https://github.com/Paul1404/VMW-OVA-Tool.git
    ```
    
2. **Run the Script**: Open PowerShell as Administrator and navigate to the directory where the script is located:
    
    ```bash
    cd path\to\VMW-OVA-Tool
    .\ova-tool.ps1
    ```
    
3. **Provide Input**:
    
    * Enter your credentials (username and password) when prompted, which will be securely stored for future use.
    * Enter the full path to the VM you wish to export (e.g., `[VCENTER-FQDN]/vm/[FOLDER]/[VM-NAME]`).
    * Enter the local path where you want the exported VM to be saved (e.g., `%userprofile%\Downloads`).
4. **Enjoy Automation**: Sit back as the script automates the entire process for you! 🎉
    

Requirements 🛠️
----------------

* **PowerShell 5.1 or later** ⚡
* **VMware OVF Tool** (automatically installed by the script if not present) 🧰
* **Internet Access** to download the OVF Tool if necessary 🌐

Contributing 🤝
---------------

Feel free to submit pull requests and report issues. Contributions are welcome! 🎉

1. Fork the repo
2. Create a feature branch (`git checkout -b feature-branch`)
3. Commit your changes (`git commit -m 'Add awesome feature'`)
4. Push to the branch (`git push origin feature-branch`)
5. Open a pull request

License 📄
----------

This project is licensed under the MIT License - see the LICENSE file for details.
