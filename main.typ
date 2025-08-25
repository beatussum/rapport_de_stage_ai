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

= Remerciements

Je remercie, tout d'abord, M. F. Wagner pour m'avoir accepté en temps que stagiaire au sein de l'équipe Datamove, ainsi que pour son aimable aide tout au long de mon séjour au @lig.

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
