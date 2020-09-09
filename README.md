# Rapid Nav
A Bash script that makes navigating and executing commands in the command line more efficient.<br />
[**Jump to Demos**](<#demos>)<br />
<br />
**Last updated (this file):** 9/9/2020<br />
**Author:** John Mullan<br />

## Usage
### Installation
1. Clone this repository
```
$ git clone https://github.com/jamullan/rapid-nav.git
```
2. If on macOS, open `~/.bash_profile`; otherwise, open `~/.bash_rc`. If the file does not exist, create it in your home directory
3. Add an alias that sources the `nav` executable, substituting the actual absolute path to this repo on your machine. Without sourcing the `nav` executable each time you wish to run it, it will not change the environment of your active shell.
```
$ alias nav="source /absolute/path/to/this/repo/nav"
```
4. Save the changes to your `~/.bash_profile` or `~/.bash_rc` file
5. Relaunch your command line application, or source your `~/.bash_profile` or `~/.bash_rc` file
```
$ source ~/.bash_profile
# OR
$ source ~/.bash_rc
```

### How to Run
In your command line application, execute the command `nav` to open the Rapid Nav utility

### Configuration Options
The variables on the first two lines of the `main` function in the `nav` Bash script, as show below set to their default values, control configuration options:
```Shell
#The width of the main menu (in units of the number of characters across)
local display_width=40
#The name that will be displayed in the main menu enclosed in an asterisks box
local host_name="My Computer"
```

## Demos
### Adding a Command
Add commands quickly, yet carefully, exactly how you prefer.<br /><br />
![Adding a Command](<demo_files/AddCommand4X.gif>)

### Running a Command
Quickly run a command with just a few key strokes. `nav`...`2` is the new `python3 -m http.server 5000`.<br /><br />
![Running a Command](<demo_files/RunCommand4X.gif>)

### Scope
A command is only available in the scope that you set. In this example, the `Start server` command is availble only when in the `SampleProject` directory or one of its subdirectories, hence its disappearance when running Rapid Nav in the `AnotherSampleProject` directory.<br /><br />
![A command will only be available if the current working directory aligns with the specifications for when that command was added](<demo_files/Scope4X.gif>)

## Future Directions
Below is a list of features that I plan to implement to improve the customizabiblity and performance of Rapid Nav:
* Implement a hash table to improve lookups from the nav_data file, on average, from O(n) to O(1)
* Validate cd commands (verify the path exists)
* Validate open commands (verify the file or directory exists)
* Add submenus
* Add option to view and edit existing commands
* Add color configuration option to settings (to further distinguish global and local commands, to colorize the main menu astericks box, etc.)
