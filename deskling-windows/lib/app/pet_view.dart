import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'pet_controller.dart';
import 'sprite.dart';

/// Draws the pet inside the transparent window and turns pointer input into controller calls.
class PetView extends StatelessWidget {
  const PetView({super.key, required this.controller, required this.sprites});

  final PetController controller;
  final SpriteCache sprites;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layout = controller.layout;
        if (layout == null) return const SizedBox.shrink();
        final pose = controller.pose;
        final skin = controller.skin;
        return Stack(
          children: [
            Positioned(
              left: layout.pet.left,
              top: layout.pet.top,
              width: layout.pet.width,
              height: layout.pet.height,
              child: Listener(
                onPointerDown: (event) {
                  if (event.buttons == kSecondaryMouseButton) {
                    controller.onInspect?.call();
                  } else if (event.buttons == kPrimaryMouseButton) {
                    controller.grab();
                  }
                },
                onPointerMove: (_) => controller.dragMoved(),
                onPointerUp: (_) => controller.drop(),
                onPointerCancel: (_) => controller.drop(),
                child: GestureDetector(
                  onDoubleTap: () => controller.onInspect?.call(),
                  child: SpriteView(
                    cache: sprites,
                    path: skin.pathFor(pose),
                    speed: skin.playbackSpeed(pose),
                    facingLeft: controller.facingLeft,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
