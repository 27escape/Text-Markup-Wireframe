## Buttons

* button (_text_) and select button (_text_v)

* (_text_)
* (_text_10)
* (_text{#.red})

* aligning {=<>^-_ #fg.bg class }      = middle, < left, > right, - vertical center, ^ vertical top, _ vertical bottom

## Input boxes

* [_text_]
* [_text_10]
* [_text{#.red}]
* text input [_text_] [_text_23_] and text area [_text_72x21_]

* aligning {=<>^-_ #fg.bg class }      = middle, < left, > right, - vertical center, ^ vertical top, _ vertical bottom

## switches

There are 3 types of switches

 ### Check Boxes

* [ ] [x] [*]
* [^] [v] [<] [>]

### Radio

* ( ) (x) (*)
* (^) (v) (<) (>)

### Toggle

* < >
* <*>
* <*{#red.blue}>

## Images

* [><]  a 50x50
* [>2<] 2x 50x50
* [>130x90<]  image of certain size
* [>_Channel Icon_130x90<] with text
* [>_some text_320x180!1280x720<] with text reporting as a different size
* if the thing starts with a '!' then we do not want to have the size on the image
    - [>!<]  a 50x50 with no size text
    - [>!2<] 2x 50x50 with no size text
    - [>!130x90<]  image of certain size but no size text
    - [>!_Channel Icon_130x90<] with text
    - [>!_some text_320x180!1280x720<] no size text



## Wireframes

### Columns

total column count needs to add up to 12

|=
|\ {col1 red} one
|\ {col1 blue} two
|\ {col1 red} three
|\ {col1 blue} four
|\ {col1 red} five
|\ {col1 blue} six
|\ {col1 red} seven
|\ {col1 blue} eight
|\ {col1 red} nine
|\ {col1 blue} ten
|\ {col1 red} eleven
|\ {col1 blue} twelve
=|


### Modals

To get an idea of modal over the top of a writeframe, use the modal construct that wraps around column layout.

|M {modal50}

|= |\ {col12 =} Upload Channel Icon =|
|= |\ {col6 ^} Requirements

* Format: PNG
* resolution: 160x120
* Filesize: 4KB

|\ {col6 ^}
[_Filename_20] (_Select_)
=|

|= |\ {col3 } &nbsp; |\ { col3 =} (_Cancel {#.salmon}_) |\ { col3 =} (_Upload {#.green200}_) =|

M|

## external items

### Pagnation

* {{.pagn content='1,!2,3,4,5,...,7' active='cignal_active'}}
* optional 'active' parameter

### Tabs


* {{.tabs content='Management,Tracker,!Filtering' }}
* optional 'active' parameter
