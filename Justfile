download:
    ./get_ensimag_logo

uml:
    plantuml -tsvg uml/nodify.puml

compile: download uml
    typst compile main.typ
