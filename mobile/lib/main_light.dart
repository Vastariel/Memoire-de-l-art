import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/colors.dart';

void main() => runApp(const _LightApp());

class _LightApp extends StatelessWidget {
  const _LightApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mémoire de l\'art',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: MdaColors.clay500),
        scaffoldBackgroundColor: MdaColors.cream50,
      ),
      home: const _TestScreen(),
    );
  }
}

class _TestScreen extends StatelessWidget {
  const _TestScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MdaColors.cream50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'Mémoire de l\'art',
                style: GoogleFonts.spectral(
                  fontSize: 32, fontWeight: FontWeight.w500,
                  color: MdaColors.ink900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Une couleur par jour, une œuvre par mois.',
                style: GoogleFonts.spectral(
                  fontStyle: FontStyle.italic, fontSize: 16,
                  color: MdaColors.ink500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Mini mosaïque de test
              _MiniMosaic(),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: MdaColors.clay100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: MdaColors.pigSienna,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COULEUR DU JOUR',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            letterSpacing: 1.4, color: MdaColors.ink500,
                          )),
                        Text('Terre de Sienne',
                          style: GoogleFonts.spectral(
                            fontSize: 20, color: MdaColors.ink900,
                          )),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MdaColors.clay500,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {},
                  child: Text('Photographier ma couleur',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16, fontWeight: FontWeight.w600,
                    )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMosaic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const cols = 14, rows = 10;
    final palette = [
      MdaColors.pigUltramarine, MdaColors.pigCobalt, MdaColors.pigOchre,
      MdaColors.pigSaffron, MdaColors.pigViridian, MdaColors.pigSienna,
      MdaColors.cream200, MdaColors.cream200, MdaColors.pigVermillion,
    ];
    return AspectRatio(
      aspectRatio: cols / rows,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, mainAxisSpacing: 3, crossAxisSpacing: 3,
        ),
        itemCount: cols * rows,
        itemBuilder: (_, i) {
          final zoneIdx = (i ~/ 20).clamp(0, palette.length - 1);
          return Container(
            decoration: BoxDecoration(
              color: palette[zoneIdx],
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}
