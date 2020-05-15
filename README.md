# SOAPfuse

Tools for oncovirus analysis from NGS data.

- Author: Wenlong Jia
- Email:  wenlongkxm@gmail.com

## Version
0.01

## Installation

To install SOAPfuse, you need to SOAPfuse FuseSV and add the current directory to the `PERL5LIB` path.
```bash
git clone https://github.com/Nobel-Justin/SOAPfuse.git
PERL5LIB=$PERL5LIB:$PWD; export PERL5LIB
```
List of additional PERL modules required:
- [JSON](https://metacpan.org/pod/JSON)
- [List::Util](https://metacpan.org/pod/List::Util)
- [Parallel::ForkManager](https://metacpan.org/pod/Parallel::ForkManager)
- [Math::Trig](https://metacpan.org/pod/Math::Trig)
- [POSIX](https://metacpan.org/pod/distribution/perl/ext/POSIX/lib/POSIX.pod)
- [SVG](https://metacpan.org/pod/SVG)
- [BioFuse](https://github.com/Nobel-Justin/BioFuse)

If you encounter problems, please open an issue at the [project on Github](https://github.com/Nobel-Justin/FuseSV/issues).
