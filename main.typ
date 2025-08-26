#import "@preview/bei-report:0.1.0": ensimag
#import "@preview/glossy:0.8.0": glossary, init-glossary, theme-compact

#show: init-glossary.with(toml("glossary.toml"))

#show: ensimag.with(
  logos: (
    company: image("logos/inria_logo.svg", height: 1fr),
    ensimag: image("logos/ensimag_logo.png", height: 1fr),
  ),
  title: [Algorithmes parallèles de graphe avec Rayon],
  author: (
    name: "Mattéo Rossillol‑‑Laruelle",
    year: [2#super[e] année],
    option: [ISI],
  ),
  period: (
    begin: datetime(year: 2025, month: 05, day: 26),
    end: datetime(year: 2025, month: 07, day: 31),
  ),
  date-fmt: "[day] [month repr:long] [year]",
  company: (
    name: [Centre Inria de l'Université Grenoble Alpes],
    address: [
      655 Avenue de l’Europe \
      38330 Montbonnot-Saint-Martin
    ]
  ),
  internship-tutor: [Frédéric Wagner],
  school-tutor: [Gaelle Calvary],
  abstract: [
    Ce rapport décrit le déroulement d'un stage effectué au @lig pendant l'été 2025.
    Ce stage s'est focalisé sur le développement d'algorithmes parallèles de graphe tout en s'appuyant sur les outils de gestion de parallélisme fournis par la @crate @rayon.

    Dans un premier temps, il a été possible d'explorer l'intérêt du développement de ce type d'outils au travers d'un problème @leetcode. Durant cette phase de prototypage, on a pu constater les avantages apportés par une programmation parallèle ainsi que ses limites.

    À l'issue de la phase précédente, on a pu développé une @crate fournissant une interface générique et permettant donc la résolution parallèle de problème faisant appel à des grahes.

    Enfin, afin d'accroître l'utilisabilité des algorithmes précédemment établis, on a pu concevoir une autre @crate s'interfaçant avec @petgraph.
  ],
  index-terms: (
    "algorithmes de graphes",
    "algorithmes parallèles",
    "ENSIMAG",
    "parallélisme de donnée",
    "rapport de stage",
  ),
  bibliography: bibliography("refs.bib"),
  figure-supplement: [Fig.],
)

= Avant-propos

== Contexte

Ce stage s'est tenu au sein de l'équipe @datamove au @lig.

Le @lig est un laboratoire de recherche qui, malgré son nom, se situe à Saint-Martin-d'Hères.
Il s'agit d'un établissement public dont la direction est partagée entre l'@uga, l'@inria et le @cnrs.
Ce laboratoire a été fondé en 2007 avec la mission d'accroître l'efficacité de la recherche en informatique : en effet, le regroupement de plusieurs équipes de spécialisation diverse vise à augmenter les collaborations transversales et le développement de projets interdisciplinaires. @bib:lig

Parmis les équipes du @lig, @datamove a pour sujet d'étude #quote[le mouvement de données pour le calcul haute performance].
En effet, pour les supercalculateurs, la bonne gestion du mouvement de donnée est un enjeu de taille : celui-ci représente, dans les faits, l'une des premières causes de ralentissement.
L'équipe divise son travail en quatre axes de recherche majeurs :
- l'intégration de l'analyse de données et du calcul intensif,
- l'ordonnancement par lot (#emph[batch]) prenant en compte les mouvements de données,
- l'étude empirique de plateformes à grande échelle, et
- la prediction de la disponibilité des ressources. @bib:datamove

== Intérêt de l'objet du stage

D'une part, une multitude de problèmes se résolvent à l'aide d'algorithmes sur des graphes : recherche d'existence de chemin, de plus court chemin ou @sssp, etc..

D'autre part, depuis les alentours des années 2000, les @moore, qui prédisaient l'augmentation constante de la puissance de calcul des processeurs, ne sont plus vérifiées.
En effet, les fabricants commencent depuis quelques années à atteindre les limites physiques.
De cette façon, l'augmentation des performances d'un algorithme ne vient plus, de nos jours, de l'utilisation d'un processeur ayant une fréquence d'horloge plus élevée, mais de la capacité à exploiter aux mieux ses unités de calcul : en d'autres termes, l'enjeu principal est devenu la parallélisation. @bib:sutter 

Ansi, bien que de nombreux algorithmes séquentiels existent, ceux dont l'éxécution est parallélisable sont devenus particulièrement intéressants.

== Mission

Au cours des lignes suivantes, on décrira deux algorithmes parallèles :
- recherche de chemin, et
- recherche de plus court chemin (ou @sssp).

On étudiera ensuite les limites de la parallèlisation.

Enfin, on fournira une interface générique à ces algorithmes.

= Introduction

== Rust et parallèlisme

=== Rust, un langage concurent

=== @rayon

== Algorithmes de graphe

=== Problème du plus court chemin

=== Recherche d'existence de chemin

== Solution développée

= Cas pratique

== Présentation du problème

=== Pertinence

== Solutions séquentielles

=== Parcours en profondeur

=== Implémentation itérative

=== Implémentation récursive

= Parallélisation

== Problématiques

=== La collection associative

== Implémentation des solutions

=== Parcours en largeur

=== Implémentation itérative

=== Itérateur parallèle

= Analyse des résultats

== Mesure de l'efficacité

== Limites du parallélisme

= Généricité

== Une @crate autonome

== Une meilleure implémentation

= Synthèse générale

== Bilan personnel

== Conclusion technique

= Remerciements

Je remercie, tout d'abord, M. F. Wagner pour m'avoir accepté en temps que stagiaire au sein de l'équipe @datamove, ainsi que pour son aimable aide tout au long de mon séjour au @lig.

Je tiens également à féliciter mes collègues qui ont pu occasionnellement m'aider au cours de ce stage : en particulier, je salue M. P. Kailer et M. V. Trophime pour leur assistance en Rust.

#let theme = (
  ..theme-compact,
  section: (title, body) => {
    heading(numbering: none, title)
    body
  },
  entry: (entry, index, total) => {
    entry.insert("description", eval(entry.description, mode: "markup"))
    (theme-compact.entry)(entry, index, total)
  },
)

#glossary(theme: theme, title: "Glossaire")
