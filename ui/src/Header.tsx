import React from "react";
import { GameStates, GameStatesRoundString } from "./helpers/GameStates";
import { GameTypes, GameTypesString } from './helpers/GameTypes';
import { useTimer } from "react-compound-timer/build/hook/useTimer";

import {  Player, Players } from "./helpers/Player";
import { Teams } from "./helpers/Teams";


import skull from './assets/img/human-skull.svg';
import like from './assets/img/helmet.svg';

import './Header.scss';

interface Props {
    teamAttackersScore: number;
    teamDefendersScore: number;
    teamAttackersClan?: string;
    teamDefendersClan?: string;
    currentScene: GameStates;
    round: number|null;
    showHud: boolean;
    gameType: GameTypes;
    bombPlantedOn: string|null;
    maxRounds: number;
    players?: Players;
}

const Header: React.FC<Props> = ({ 
    teamAttackersClan,
    teamDefendersClan,
    teamAttackersScore,
    teamDefendersScore,
    currentScene,
    round,
    showHud,
    gameType,
    bombPlantedOn,
    maxRounds,
    players
 }) => {
    window.SetTimer = function(p_Time: number) {
        setTime(1000 * p_Time);
        start();
        reset();
    }

    const { value, controls: { setTime, reset, start }} = useTimer({ initialTime: 0, direction: "backward", startImmediately: false });

    return (
        <>
            <div id="promodHeader">
                Promod
            </div>

            <div id="promodVersion">
                v 0.8
            </div>

            <div id="debug">
                <button onClick={() => window.SetTimer(300)}>300 sec</button>
                <button onClick={() => window.SetTimer(200)}>200 sec</button>
                <button onClick={() => window.SetTimer(100)}>100 sec</button>
            </div>

            {showHud &&
                <div id="inGameHeader" className="fadeInTop">
                    <div className="playerIcons attackers">
                        {(players !== undefined && players[Teams.Attackers].length > 0) &&
                            <>
                                {players[Teams.Attackers].map((player: Player, index: number) => (
                                    <div key={index} className={"playerIcon " + (player.isDead?'isDead':'isAlive') + " isAttacker"}>
                                        {player.isDead ?
                                            <img src={skull} alt="Dead" />
                                        :
                                            <img src={like} alt="Alive" />
                                        }
                                    </div>
                                ))}
                            </>
                        }
                    </div>
                    <div id="score">
                        <div id="scoreAttackers">
                            {/*<span id="team">Attackers</span>*/}
                            <span className="points">{teamAttackersScore??0}</span>
                        </div>
                        <div id="roundTimer">
                            <span className={"timer " + (bombPlantedOn !== null ? 'planted' : '')}>
                                {(value !== null)
                                ?
                                    <>
                                        {(value.m < 10 ? `0${value.m}` : value.m)}:{(value.s < 10 ? `0${value.s}` : value.s)}
                                    </>
                                :
                                    <>
                                        00:00
                                    </>
                                }
                            </span>
                            <span className="round">
                                {bombPlantedOn !== null 
                                ?
                                    <>
                                        Bomb on {bombPlantedOn}
                                    </>
                                :
                                    <>
                                        {GameStatesRoundString[currentScene].replace('{round}', ((round?.toString()??'1') + '/' + maxRounds))??''}
                                    </>
                                }
                            </span>

                            <div className="gameTypeLabel">
                                {GameTypesString[gameType]}
                            </div>
                        </div>
                        <div id="scoreDefenders">
                            {/*<span id="team">Defenders</span>*/}
                            <span className="points">{teamDefendersScore??0}</span>
                        </div>
                    </div>
                    <div className="playerIcons defenders">
                        {(players !== undefined && players[Teams.Defenders].length > 0) &&
                            <>
                                {players[Teams.Defenders].map((player: Player, index: number) => (
                                    <div key={index} className={"playerIcon " + (player.isDead?'isDead':'isAlive') + " isDefender"}>
                                        {player.isDead ?
                                            <img src={skull} alt="Dead" />
                                        :
                                            <img src={like} alt="Alive" />
                                        }
                                    </div>
                                ))}
                            </>
                        }
                    </div>
                </div>
            }
        </>
    );
};

Header.defaultProps = {
    currentScene: GameStates.None,
    teamAttackersScore: 0,
    teamDefendersScore: 0,
    round: 0,
};

export default Header;

declare global {
    interface Window {
        SetTimer: (p_Time: number) => void;
    }
}
