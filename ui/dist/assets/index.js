import {
    r as y,
    o as h,
    c as g,
    a as e,
    b as t,
    w as i,
    d as p,
    F as v,
    e as k,
    f as w,
    t as l,
    g as P,
    h as S,
    i as R,
    j as C,
    k as E
} from "./vendor.js";
(function() {
    const s = document.createElement("link").relList;
    if (s && s.supports && s.supports("modulepreload")) return;
    for (const r of document.querySelectorAll('link[rel="modulepreload"]')) c(r);
    new MutationObserver(r => {
        for (const o of r)
            if (o.type === "childList")
                for (const d of o.addedNodes) d.tagName === "LINK" && d.rel === "modulepreload" && c(d)
    }).observe(document, {
        childList: !0,
        subtree: !0
    });

    function f(r) {
        const o = {};
        return r.integrity && (o.integrity = r.integrity), r.referrerPolicy && (o.referrerPolicy = r.referrerPolicy), r.crossOrigin === "use-credentials" ? o.credentials = "include" : r.crossOrigin === "anonymous" ? o.credentials = "omit" : o.credentials = "same-origin", o
    }

    function c(r) {
        if (r.ep) return;
        r.ep = !0;
        const o = f(r);
        fetch(r.href, o)
    }
})();
const W = (a, s) => {
    const f = a.__vccOpts || a;
    for (const [c, r] of s) f[c] = r;
    return f
};

function b(a) {
    return new Promise(s => setTimeout(s, a))
}
const F = {
        data() {
            return {
                viewPokerGame: !1,
                game: void 0,
                thisPlayer: void 0,
                winScenario: void 0,
                revealing: !1,
                pendingUpdate: void 0
            }
        },
        mounted() {
            let a = this;
            window.addEventListener("message", this.onMessage), window.addEventListener("keyup", function(s) {
                s.key == "Escape" && a.fireEvent("closeAll")
            })
        },
        destroyed() {
            window.removeEventListener("message"), window.removeEventListener("keyup")
        },
        methods: {
            async onMessage(a) {
                a.data.type === "start" && (this.viewPokerGame = !0, this.game = a.data.game, this.thisPlayer = a.data.thisPlayer, this.winScenario = void 0), a.data.type === "update" && (async()=>{ if(this.revealing){ this.pendingUpdate = a; return } const ps=this.game&&this.game.step, ns=a.data.game&&a.data.game.step; const adv=(ps=="INITIAL"&&ns=="FLOP")||(ps=="FLOP"&&ns=="TURN")||(ps=="TURN"&&ns=="RIVER"); if(adv){ this.revealing=!0; if(ps=="INITIAL"&&ns=="FLOP"){ await b(1e3); this.fireEvent("playCardFlip"); this.game.board.cardV.isRevealed=!0; await b(1100); this.fireEvent("playCardFlip"); this.game.board.cardW.isRevealed=!0; await b(1200); this.fireEvent("playCardFlip"); this.game.board.cardX.isRevealed=!0 } else if(ps=="FLOP"&&ns=="TURN"){ await b(1e3); this.fireEvent("playCardFlip"); this.game.board.cardY.isRevealed=!0 } else if(ps=="TURN"&&ns=="RIVER"){ await b(1e3); this.fireEvent("playCardFlip"); this.game.board.cardZ.isRevealed=!0 } this.game = a.data.game; this.thisPlayer = a.data.thisPlayer; this.revealing=!1; if(this.pendingUpdate){ const u=this.pendingUpdate; this.pendingUpdate=void 0; await this.onMessage(u) } } else { this.game = a.data.game; this.thisPlayer = a.data.thisPlayer } })(), a.data.type === "win" && (this.winScenario = a.data.winScenario, this.winScenario.thisPlayersWinningHand && (this.winScenario.thisPlayersWinningHand.winningHandType = this.winScenario.thisPlayersWinningHand.winningHandType.toString().replace(/_/g, " "))), a.data.type === "close" && (this.viewPokerGame = !1, this.game = void 0, this.thisPlayer = void 0, this.winScenario = void 0)
            },
            fireEvent(a, s = {}) {
                fetch(`https://${GetParentResourceName()}/` + a, {
                    method: "POST",
                    body: JSON.stringify(s)
                })
            },
            translateCardToPng(a, s, f) {
                if (a) {
                    let c;
                    switch (f) {
                        case "s":
                            c = "spades";
                            break;
                        case "c":
                            c = "clubs";
                            break;
                        case "d":
                            c = "diamonds";
                            break;
                        case "h":
                            c = "hearts";
                            break
                    }
                    return "/ui/public/img/card/" + c + "_" + s.toLowerCase() + ".png"
                }
                return "/ui/public/img/card/back.png"
            },
            getThisRoundsActionFromPlayer(a) {
                if (a.hasFolded) return "Folded";
                if (a.order == this.game.currentTurn) return "Deciding";
                switch (this.game&&this.game.step) {
                    case "INITIAL":
                        return a.actionInitial ?? "Waiting";
                    case "FLOP":
                        return a.actionFlop ?? "Waiting";
                    case "TURN":
                        return a.actionTurn ?? "Waiting";
                    case "RIVER":
                        return a.actionRiver ?? "Waiting";
                    default:
                        return ""
                }
            },
            describeHand(a){try{const h=a||this.winScenario&&this.winScenario.winningHand;if(!h)return"";const cards=h.cards||[];const type=(h.winningHandType||"").toString().replace(/_/g," ");const ranks=cards.map(c=>(c.royalty||"").toString().toUpperCase());const order=["2","3","4","5","6","7","8","9","10","T","J","Q","K","A"];const name=r=>({A:"Ace",K:"King",Q:"Queen",J:"Jack",T:"10","10":"10"}[r]||r);const counts={};for(const r of ranks)counts[r]=(counts[r]||0)+1;const sorted=[...ranks].sort((a,b)=>order.indexOf(a)-order.indexOf(b));const high=name(sorted[sorted.length-1]||"");switch((h.winningHandType||"").toString()){case"ONE_PAIR":{const pr=Object.keys(counts).find(r=>counts[r]===2);return`Pair of ${name(pr)}s`;}case"TWO_PAIRS":{const prs=Object.keys(counts).filter(r=>counts[r]===2).sort((a,b)=>order.indexOf(a)-order.indexOf(b));const hi=name(prs[prs.length-1]);const lo=name(prs[prs.length-2]);return`Two pair, ${hi}s and ${lo}s`;}case"THREE_OF_A_KIND":{const tr=Object.keys(counts).find(r=>counts[r]===3);return`Three of a kind, ${name(tr)}s`;}case"STRAIGHT":return`Straight, ${high} high`;case"STRAIGHT_FLUSH":return`Straight flush, ${high} high`;case"FLUSH":return`Flush, ${high} high`;case"FULL_HOUSE":{const tr=Object.keys(counts).find(r=>counts[r]===3);const pr=Object.keys(counts).find(r=>counts[r]===2);return`Full house, ${name(tr)}s over ${name(pr)}s`;}case"FOUR_OF_A_KIND":{const qr=Object.keys(counts).find(r=>counts[r]===4);return`Four of a kind, ${name(qr)}s`;}case"ROYAL_FLUSH":return"Royal flush";case"HIGH_CARD":default:return`${high} high`;} }catch(_){return a&&a.winningHandType?a.winningHandType.toString().replace(/_/g," "):"";} }
        }
    },
    N = {
        key: 0,
        class: "wrapper"
    },
    A = {
        class: "poker-box"
    },
    B = {
        id: "board-box",
        class: "d-flex justify-center"
    },
    L = {
        id: "board-cards",
        class: "d-flex"
    },
    H = {
        id: "board-card-V",
        class: "card board-card"
    },
    I = {
        id: "board-card-W",
        class: "card board-card"
    },
    O = {
        id: "board-card-X",
        class: "card board-card"
    },
    V = {
        id: "board-card-Y",
        class: "card board-card"
    },
    Y = {
        id: "board-card-Z",
        class: "card board-card"
    },
    G = {
        id: "hole-box-container",
        class: "position-absolute bottom-0 w-100"
    },
    D = {
        id: "hole-box",
        class: "d-flex justify-center"
    },
    X = {
        id: "hole-cards",
        class: "d-flex"
    },
    Z = {
        id: "hole-card-A",
        class: "card hole-card"
    },
    j = {
        id: "hole-card-B",
        class: "card hole-card"
    },
    $ = {
        id: "players-box"
    },
    M = {
        key: 0
    },
    U = {
        class: "d-flex pl-3",
        style: {
            "column-gap": "8px",
            "align-items": "center"
        }
    },
    q = {
        class: "card player-card"
    },
    z = {
        class: "card player-card"
    },
    J = {
        class: "text-lime player-name",
        style: {
            "font-size": "20px"
        }
    },
    K = {
        class: "text-amber-lighten-3"
    },
    Q = {
        class: "text-amber"
    },
    ee = {
        class: "text-amber-lighten-3"
    },
    te = {
        class: "text-amber"
    },
    se = {
        key: 0,
        class: "win-box-container"
    },
    ae = {
        id: "win-box",
        class: "d-flex justify-center"
    },
    ie = {
        key: 0,
        class: "text-center"
    },
    re = {
        key: 1,
        class: "text-center"
    },
    ne = {
        class: "win-message"
    },
    oe = {
        class: "win-message"
    },
    de = {
        class: "text-amber"
    },
    le = {
        key: 2,
        class: "text-center"
    },
    ce = {
        class: "win-message"
    },
    ue = {
        class: "win-message"
    },
    he = {
        class: "win-message"
    },
    me = {
        class: "text-amber"
    };

function ge(a, s, f, c, r, o) {
    const d = y("v-img"),
        n = y("v-col"),
        m = y("v-row"),
        _ = y("v-container"),
        x = y("v-icon"),
        T = y("v-sheet");
    return h(), g(v, null, [s[9] || (s[9] = e("header", null, null, -1)), e("main", null, [r.viewPokerGame && r.game && r.game.step != "pending" ? (h(), g("div", N, [e("div", A, [e("div", B, [t(_, {
        class: "w-auto px-10 py-3 mt-5"
    }, {
        default: i(() => [t(m, null, {
            default: i(() => [t(n, null, {
                default: i(() => [e("div", L, [e("div", H, [t(d, {
                    src: this.translateCardToPng(this.game.board.cardV.isRevealed, this.game.board.cardV.royalty, this.game.board.cardV.suit),
                    width: "64"
                }, null, 8, ["src"])]), e("div", I, [t(d, {
                    src: this.translateCardToPng(this.game.board.cardW.isRevealed, this.game.board.cardW.royalty, this.game.board.cardW.suit),
                    width: "64"
                }, null, 8, ["src"])]), e("div", O, [t(d, {
                    src: this.translateCardToPng(this.game.board.cardX.isRevealed, this.game.board.cardX.royalty, this.game.board.cardX.suit),
                    width: "64"
                }, null, 8, ["src"])]), e("div", V, [t(d, {
                    src: this.translateCardToPng(this.game.board.cardY.isRevealed, this.game.board.cardY.royalty, this.game.board.cardY.suit),
                    width: "64"
                }, null, 8, ["src"])]), e("div", Y, [t(d, {
                    src: this.translateCardToPng(this.game.board.cardZ.isRevealed, this.game.board.cardZ.royalty, this.game.board.cardZ.suit),
                    width: "64"
                }, null, 8, ["src"])])])]),
                _: 1
            })]),
            _: 1
        })]),
        _: 1
    })]), e("div", G, [e("div", D, [t(_, {
        class: "ma-5 w-auto px-10 py-3"
    }, {
        default: i(() => [t(m, null, {
            default: i(() => [t(n, null, {
                default: i(() => [e("div", X, [e("div", Z, [t(d, {
                    src: this.translateCardToPng(!0, r.thisPlayer.cardA.royalty, r.thisPlayer.cardA.suit),
                    width: "64"
                }, null, 8, ["src"])]), e("div", j, [t(d, {
                    src: this.translateCardToPng(!0, r.thisPlayer.cardB.royalty, r.thisPlayer.cardB.suit),
                    width: "64"
                }, null, 8, ["src"])])])]),
                _: 1
            })]),
            _: 1
        })]),
        _: 1
    })])]), e("div", $, [t(T, {
        class: "pb-0",
        style: {
            "background-color": "rgba(0, 0, 0, 0.4)",
            "position": "absolute",
            "top": "0",
            "left": "0",
            "overflow": "hidden"
        },
        width: "15%",
        rounded: ""
    }, {
        default: i(() => [t(_, {
            class: "mx-0 mb-0 w-auto px-10 py-0"
        }, {
            default: i(() => [t(m, null, {
                default: i(() => [t(n, {
                    cols: "12"
                }, {
                    default: i(() => [t(_, {
                        class: "pa-0"
                    }, {
                        default: i(() => [t(m, {
                            class: "table-pot-row"
                        }, {
                            default: i(() => [t(n, {
                                cols: "12"
                            }, {
                                default: i(() => [e("span", { class: "text-amber-lighten-3", style: { "font-size": "24px", "font-weight": "700" } }, "Table Pot: ", -1), e("span", { class: "text-amber", style: { "font-size": "24px", "font-weight": "700", "margin-left": "6px" } }, "$" + l(this.game.bettingPool), 1)]),
                                _: 1
                            })]),
                            _: 1
                        }), (h(!0), g(v, null, k(this.game.players, u => (h(), P(m, {
                            class: "player"
                        }, {
                            default: i(() => [t(n, {
                                cols: "12",
                                class: "pa-0"
                            }, {
                                default: i(() => [t(_, {
                                    class: "pb-0"
                                }, {
                                    default: i(() => [(h(), g("div", M, [t(m, {
                                        class: "player-cards",
                                        style: { "margin-bottom": "0" }
                                    }, {
                                        default: i(() => [t(n, {
                                            cols: "12",
                                            class: "pa-0"
                                        }, {
                                            default: i(() => [e("div", U, [e("span", J, l(u.name) + ": ", 1), e("div", q, [t(d, {
                                                src: this.translateCardToPng(u.cardA.isRevealed, u.cardA.royalty, u.cardA.suit),
                                                width: "32",
                                                height: "90",
                                                style: { "transform": "scale(0.5)", "transform-origin": "top", "display": "overlay" }
                                            }, null, 8, ["src"])]), e("div", z, [t(d, {
                                                src: this.translateCardToPng(u.cardB.isRevealed, u.cardB.royalty, u.cardB.suit),
                                                width: "32",
                                                height: "90",
                                                style: { "transform": "scale(0.5)", "transform-origin": "top", "display": "overlay" }
                                            }, null, 8, ["src"])])])]),
                                            _: 2
                                        }, 1024)]),
                                        _: 2
                                    }, 1024)])), t(m, {
                                        class: "player-data ma-0 pa-0",
                                        style: { "margin-top": "0" }
                                    }, {
                                        default: i(() => [t(n, {
                                            cols: "12",
                                            class: "player-data-item pb-0"
                                        }, {
                                            default: i(() => [e("span", { class: "text-amber", style: { "font-size": "14px" } }, "Cash: $" + l(u.isNpc ? u.npcCash : u.playerCash), 1)]),
                                            _: 2
                                        }, 1024), t(n, {
                                            cols: "12",
                                            class: "player-data-item pb-0"
                                        }, {
                                            default: i(() => [e("span", { style: { "font-size": "14px" } }, "Action: " + l(o.getThisRoundsActionFromPlayer(u) + (u.amountBetInRound > 0 ? " $" + u.amountBetInRound : "")), 1)]),
                                            _: 2
                                        }, 1024), t(n, {
                                            cols: "12",
                                            class: "player-data-item pb-0"
                                        }, {
                                            default: i(() => [e("span", { class: "text-amber", style: { "font-size": "14px" } }, "Total Bet: $" + l(u.totalAmountBetInGame), 1)]),
                                            _: 2
                                        }, 1024)]),
                                        _: 2
                                    }, 1024)]),
                                    _: 2
                                }, 1024)]),
                                _: 2
                            }, 1024)]),
                            _: 2
                        }, 1024))), 256)), p("", !0), p("", !0)]),
                        _: 1
                    })]),
                    _: 1
                })]),
                _: 1
            })]),
            _: 1
        })]),
        _: 1
    })])]), this.winScenario ? (h(), g("div", se, [e("div", ae, [t(_, {
        class: "win-box-vcontainer w-auto pa-10"
    }, {
        default: i(() => [t(m, {
            class: "px-5"
        }, {
            default: i(() => [t(n, null, {
                default: i(() => [this.winScenario.thisPlayersWinningHand ? p("", !0) : (h(), g("div", ie, [e("h3", { class: "win-title text-red-accent-3" }, "LOSE"), e("div", ne, l(((this.game.players.find(u => u.netId === this.winScenario.winningHand.playerNetId) || {}).name) + " won $" + this.game.bettingPool), 1), e("div", oe, l(this.describeHand(this.winScenario.winningHand)), 1)])), this.winScenario.isTrueTie == !1 && this.winScenario.thisPlayersWinningHand ? (h(), g("div", re, [e("h3", { class: "win-title text-green-accent-3" }, "WIN"), e("div", ne, l(((this.game.players.find(u => u.netId === this.winScenario.winningHand.playerNetId) || {}).name) + " won $" + this.game.bettingPool), 1), e("div", oe, l(this.describeHand(this.winScenario.winningHand)), 1)])) : p("", !0), this.winScenario.isTrueTie == !0 && this.winScenario.thisPlayersWinningHand ? (h(), g("div", le, [e("h3", { class: "win-title text-green-lighten-2" }, "WIN"), e("div", ce, l("Tie: " + this.winScenario.tiedHands.length + " winners, each won $" + (this.game.bettingPool / this.winScenario.tiedHands.length)), 1), e("div", ue, l(this.describeHand(this.winScenario.tiedHands && this.winScenario.tiedHands[0])), 1)])) : p("", !0)]),
                _: 1
            })]),
            _: 1
        })]),
        _: 1
    })])])) : p("", !0)])) : p("", !0)])], 64)
}
const fe = W(F, [
    ["render", ge]
]);
const pe = {
        dark: !1,
        colors: {
            background: "transparent",
            surface: "#000000",
            primary: "#6200EE",
            "primary-darken-1": "#3700B3",
            secondary: "#03DAC6",
            "secondary-darken-1": "#018786",
            error: "#B00020",
            info: "#2196F3",
            success: "#4CAF50",
            warning: "#FB8C00"
        }
    },
    _e = S({
        components: C,
        directives: E,
        theme: {
            defaultTheme: "myCustomDarkTheme",
            themes: {
                myCustomDarkTheme: pe
            }
        }
    });
R(fe).use(_e).mount("#app");