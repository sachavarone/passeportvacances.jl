# instantiate a project

using Pkg
Pkg.add("PkgTemplates")

using PkgTemplates
t = Template(;
           user="sachavarone",
           authors=["Sacha Varone"],
           plugins=[
               License(name="MIT"),
               Git(),
               GitHubActions(),
           ],
       )
t("passeportvacances")
