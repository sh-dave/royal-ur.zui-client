package;

import ur.Game;

import zui.Id;
import zui.Zui;

class Main {
    public static function main() {
        kha.System.start({ width: 384, height: 350 }, function( _ ) {
            kha.Assets.loadEverything(boot);
        });
    }

    static function boot() {
        var game = new Game({
            // Opt_JumpOverStarTokens: true,

            TokenCount: 7,
            DiceCount: 4,

            board: [
                Star,	Normal, Normal, Normal,	/*s2*/Normal,	/*e2*/Normal,   Star,   Normal,
                Normal,	Normal, Normal, Star,	Normal,	Normal, Normal,	Normal,
                Star,	Normal, Normal, Normal,	/*s1*/Normal,	/*e1*/Normal,   Star,	Normal,
            ],

            player1: new Player({ id: 1 }),
            player2: new Player({ id: 2 }),

            path1: [20, 19, 18, 17, 16, 8, 9, 10, 11, 12, 13, 14, 6, 7, 15, 23, 22, 21],
            path2: [4, 3, 2, 1, 0, 8, 9, 10, 11, 12, 13, 14, 22, 23, 15, 7, 6, 5],
        });

        var z = new Zui({ font: kha.Assets.fonts._04B_21 });
        var autoplay = false;

        kha.Scheduler.addTimeTask(function() {
            if (autoplay) {
                switch game.state {
                    case InProgress(g, phase):
                        switch phase {
                            case RollDicePhase:
                                game.rollDice();
                            case MoveTokenPhase:
                                final candidates = (game.currentPlayer == 1 ? g.tok1 : g.tok2).toArray();
                                final rnd = Std.random(candidates.length);
                                final pos = candidates[rnd];
                                final steps = g.dice.fold((a, total) -> a + total, 0);
                                final canMove = game.hasValidMoves(g, game.currentPlayer, steps);

                                if (steps == 0 || !canMove) {
                                    game.skipMoveToken();
                                } else {
                                    game.moveToken(pos);
                                }
                        }
                    case Won(g, winner):
                }
            }
        }, 0, 1 / 20);

        kha.System.notifyOnFrames(function( fbs ) {
            var fb = fbs[0];
            var g2 = fb.g2;
            var uiWidth = 384;

            function drawPlayer( pid: Int ) {
                z.text('PLAYER $pid', Center);

                switch game.state {
                    case InProgress(g, phase):
                        if (game.currentPlayer == pid) {
                            switch phase {
                                case RollDicePhase:
                                    if (z.button('ROLL DICE')) {
                                        game.rollDice().handle(o -> trace(o));
                                    }
                                    z.text('');
                                case MoveTokenPhase:
                                    var steps = g.dice.fold((a, total) -> a + total, 0);
                                    var allBlocked = !game.hasValidMoves(g, game.currentPlayer, steps);

                                    if (steps == 0) {
                                        if (z.button('SKIP MOVEMENT (DICE = 0)')) {
                                            game.skipMoveToken().handle(o -> trace(o));
                                        }

                                        z.text('');
                                    } else if (allBlocked) {
                                        if (z.button('SKIP MOVEMENT (BLOCKED)')) {
                                            game.skipMoveToken().handle(o -> trace(o));
                                        }

                                        z.text('');
                                    } else {
                                        z.text('MOVE: $steps FIELDS');
                                        z.text('');
                                    }
                            }
                        } else {
                            z.text('OTHER PLAYERS TURN', Center);
                            z.text('');
                        }
                    case Won(_, winner):
                        z.text(winner == pid ? 'WINNER' : 'LOOSER', Center);
                        z.text('');
                }
            }

            g2.begin(true, kha.Color.fromBytes(0x33, 0x33, 0x33));
            g2.end();

            z.alwaysRedraw = true;
            z.begin(g2);
                if (z.window(Id.handle(), 0, 0, uiWidth, 512)) {

                    drawPlayer(2);

                    z.separator();

                    var brd = game.board.toArray().map(x -> switch x {
                        case null: '';
                        case Normal: ' ';
                        case Star: '* ';
                    });

                    var start1Cnt = switch game.state {
                        case InProgress(g, _), Won(g, _):
                            g.tok1.count(t -> t == 20);
                    }

                    var end1Cnt = switch game.state {
                        case InProgress(g, _), Won(g, _):
                            g.tok1.count(t -> t == 21);
                    }

                    var start2Cnt = switch game.state {
                        case InProgress(g, _), Won(g, _):
                            g.tok2.count(t -> t == 4);
                    }

                    var end2Cnt = switch game.state {
                        case InProgress(g, _), Won(g, _):
                            g.tok2.count(t -> t == 5);
                    }

                    switch game.state {
                        case InProgress(g, _), Won(g, _):
                            for (t1 in g.tok1.toArray()) {
                                brd[t1] += '1';
                            }

                            for (t2 in g.tok2.toArray()) {
                                brd[t2] += '2';
                            }
                    }

                    z.row([1 / 7, 2 / 7, 1 / 7, 2 / 7, 1 / 7]);
                        z.text('');
                        if (z.button('IN: $start2Cnt')) {
                            game.moveToken(4);
                        };
                        z.text('');
                        z.text('SAVED: $end2Cnt');
                        z.text('');

                    for (row in 0...3) {
                        z.row([for (i in 0...8) 1 / 8]);

                        for (col in 0...8) {
                            var txt = brd[row * 8 + col];

                            switch [col, row] {
                                case [4, 0], [4, 2]:
                                    z.text('<IN');
                                case [5, 0], [5, 2]:
                                    z.text('OUT<');
                                case _:
                                    if (z.button(txt)) {
                                        game.moveToken(row * 8 + col).handle(o -> trace(o));
                                    }
                            }
                        }
                    }

                    z.row([1 / 7, 2 / 7, 1 / 7, 2 / 7, 1 / 7]);
                        z.text('');
                        if (z.button('IN: $start1Cnt')) {
                            game.moveToken(20);
                        }
                        z.text('');
                        z.text('SAVED: $end1Cnt');
                        z.text('');

                    z.separator();

                    drawPlayer(1);

                    z.separator();

                    autoplay = z.check(Id.handle({ selected: autoplay }), 'AUTOPLAY');

                    if (z.button('RESET')) {
                        game.reset();
                    }

                    // if (z.button('DUMP HISTORY')) {
                    //     var raw = game.actions.toArray();
                    //     var json = haxe.Json.stringify(raw);
                    //     trace(json);
                    // }
                }
            z.end();
        });
    }
}
